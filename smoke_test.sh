#!/bin/bash
# Smoke test: execute the notebook end-to-end headlessly.
# This project does NOT use the shared smoke_test_all.sh FastAPI-on-8111 pattern.
set -euo pipefail

cd "$(dirname "$0")"

OUT=/tmp/medallion_smoke_out.ipynb
TIMEOUT_S=300

echo "Executing data_engineering.ipynb (timeout ${TIMEOUT_S}s)..."
uv run jupyter nbconvert \
    --to notebook \
    --execute data_engineering.ipynb \
    --output "$OUT" \
    --ExecutePreprocessor.timeout=$TIMEOUT_S

if [ -f "$OUT" ]; then
    echo "PASS: notebook executed end-to-end -> $OUT"
    exit 0
else
    echo "FAIL: notebook did not produce output"
    exit 1
fi
