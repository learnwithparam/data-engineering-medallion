#!/bin/bash
# E2E smoke test for data-engineering-medallion.
#
# Executes the notebook headless and validates that every medallion stage
# produced its expected artefact. This is the notebook-project equivalent of
# the FastAPI-per-endpoint checks the shared ../smoke_test_all.sh runs for the
# other two data-engineering projects.
set -uo pipefail

cd "$(dirname "$0")"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; PASSED=$((PASSED+1)); }
fail() { echo -e "  ${RED}FAIL${NC}: $1"; FAILED=$((FAILED+1)); }
info() { echo -e "  ${BLUE}$1${NC}"; }

echo -e "${BLUE}=== data-engineering-medallion ===${NC}"

# ----------------------------------------------------------------------------
# 1. uv sync — reproduce the environment
# ----------------------------------------------------------------------------
info "Running uv sync..."
if uv sync > /tmp/medallion_sync.log 2>&1; then
    pass "uv sync"
else
    fail "uv sync failed"
    tail -20 /tmp/medallion_sync.log
    exit 1
fi

# ----------------------------------------------------------------------------
# 2. Clean prior artefacts so we measure what THIS run produced
# ----------------------------------------------------------------------------
rm -f bronze_hackerone_reports.parquet raw_data.csv hackerone.duckdb hackerone.duckdb.wal
rm -rf out/charts out/section_metadata

# ----------------------------------------------------------------------------
# 3. Execute the notebook headless
# ----------------------------------------------------------------------------
OUT=/tmp/medallion_smoke_out.ipynb
TIMEOUT_S=600
info "Executing data_engineering.ipynb (timeout ${TIMEOUT_S}s)..."
if uv run jupyter nbconvert \
        --to notebook \
        --execute data_engineering.ipynb \
        --output "$OUT" \
        --ExecutePreprocessor.timeout=$TIMEOUT_S \
        > /tmp/medallion_nbconvert.log 2>&1; then
    pass "notebook executed end-to-end"
else
    fail "notebook execution failed"
    tail -30 /tmp/medallion_nbconvert.log
    exit 1
fi

# ----------------------------------------------------------------------------
# 4. Validate no cell emitted an error output
# ----------------------------------------------------------------------------
info "Scanning executed notebook for cell errors..."
ERR_COUNT=$(uv run python -c "
import json, sys
nb = json.load(open('$OUT'))
errs = 0
for cell in nb.get('cells', []):
    for out in cell.get('outputs', []):
        if out.get('output_type') == 'error':
            errs += 1
print(errs)
" 2>/dev/null || echo "unknown")
if [ "$ERR_COUNT" = "0" ]; then
    pass "zero cell errors in executed notebook"
else
    fail "$ERR_COUNT cell(s) raised during execution"
fi

# ----------------------------------------------------------------------------
# 5. Validate notebook structure (markdown + code cell mix)
# ----------------------------------------------------------------------------
STRUCTURE=$(uv run python -c "
import json
nb = json.load(open('$OUT'))
md = sum(1 for c in nb['cells'] if c['cell_type']=='markdown')
code = sum(1 for c in nb['cells'] if c['cell_type']=='code')
print(f'{md},{code}')
" 2>/dev/null || echo "0,0")
MD_N="${STRUCTURE%,*}"
CODE_N="${STRUCTURE#*,}"
if [ "${CODE_N:-0}" -ge 20 ] && [ "${MD_N:-0}" -ge 5 ]; then
    pass "notebook has $MD_N markdown + $CODE_N code cells"
else
    fail "notebook structure off (md=$MD_N code=$CODE_N)"
fi

# ----------------------------------------------------------------------------
# 6. Bronze layer: raw parquet ingest
# ----------------------------------------------------------------------------
if [ -s bronze_hackerone_reports.parquet ]; then
    SZ=$(wc -c < bronze_hackerone_reports.parquet | tr -d ' ')
    pass "bronze parquet written (${SZ} bytes)"
else
    fail "bronze_hackerone_reports.parquet missing or empty"
fi

if [ -s raw_data.csv ]; then
    LINES=$(wc -l < raw_data.csv | tr -d ' ')
    pass "raw CSV written (${LINES} lines)"
else
    fail "raw_data.csv missing or empty"
fi

# ----------------------------------------------------------------------------
# 7. Silver/Gold/Marts: DuckDB warehouse with expected tables
# ----------------------------------------------------------------------------
if [ -s hackerone.duckdb ]; then
    pass "duckdb warehouse file created"

    TABLES=$(uv run python -c "
import duckdb
con = duckdb.connect('hackerone.duckdb', read_only=True)
rows = con.execute(\"SELECT table_schema, table_name FROM information_schema.tables ORDER BY table_schema, table_name\").fetchall()
print(len(rows))
for schema, tbl in rows:
    print(f'{schema}.{tbl}')
" 2>/dev/null)
    TBL_COUNT=$(echo "$TABLES" | head -1)
    if [ "${TBL_COUNT:-0}" -ge 3 ]; then
        pass "duckdb has $TBL_COUNT tables across medallion layers"
        echo "$TABLES" | tail -n +2 | sed 's/^/        /'
    else
        fail "duckdb has only ${TBL_COUNT:-0} tables (expected >= 3)"
    fi
else
    fail "hackerone.duckdb missing"
fi

# ----------------------------------------------------------------------------
# 8. Visualisation layer: 10 charts in out/charts/
# ----------------------------------------------------------------------------
if [ -d out/charts ]; then
    CHART_COUNT=$(ls out/charts/*.png 2>/dev/null | wc -l | tr -d ' ')
    if [ "${CHART_COUNT:-0}" -ge 10 ]; then
        pass "$CHART_COUNT PNG charts rendered to out/charts/"
    else
        fail "only ${CHART_COUNT:-0} charts found (expected 10)"
    fi
else
    fail "out/charts directory missing"
fi

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
echo -e "\n${BLUE}==============================${NC}"
echo -e "${BLUE}  MEDALLION SMOKE RESULTS${NC}"
echo -e "${BLUE}==============================${NC}"
echo -e "  ${GREEN}Passed:  $PASSED${NC}"
echo -e "  ${RED}Failed:  $FAILED${NC}"
echo -e "${BLUE}==============================${NC}"

[ $FAILED -eq 0 ]
