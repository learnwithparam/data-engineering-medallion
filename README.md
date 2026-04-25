# Data engineering foundations with the medallion pattern

[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![DuckDB](https://img.shields.io/badge/DuckDB-FFF000?logo=duckdb&logoColor=black)](https://duckdb.org/)
[![Pandas](https://img.shields.io/badge/Pandas-150458?logo=pandas&logoColor=white)](https://pandas.pydata.org/)
[![Jupyter](https://img.shields.io/badge/Jupyter-F37626?logo=jupyter&logoColor=white)](https://jupyter.org/)
[![learnwithparam](https://img.shields.io/badge/learnwithparam.com-0a0a0a?logo=readthedocs&logoColor=white)](https://www.learnwithparam.com)

Beginner-friendly data engineering workshop: take a public dataset from **raw -> cleaned -> star schema -> quality checks -> BI-ready marts -> charts** in a single notebook.

This is the starting point for the [learnwithparam.com](https://www.learnwithparam.com) data engineering track. No distributed system, no orchestration, just DuckDB, pandas, and the warehouse pattern every serious data platform eventually depends on.

Start the free course: [learnwithparam.com/courses/data-engineering-medallion](https://www.learnwithparam.com/courses/data-engineering-medallion)
Continue into the full program: [learnwithparam.com/data-engineering-bootcamp](https://www.learnwithparam.com/data-engineering-bootcamp)

## What you'll build

By the end of the notebook you will have:

- A **Bronze** layer: the raw dataset registered in DuckDB, untouched.
- A **Silver** layer: cleaned, deduped, typed, with standardized column names.
- A **Gold** layer: a proper **star schema** — one fact table, multiple dimension tables, surrogate keys, referential integrity.
- A **Quality gate**: row counts, null checks, foreign-key checks, domain-value checks.
- **Business marts**: aggregates curated for BI/APIs/AI features.
- **Charts**: rendered from marts so BI tools and the notebook agree.

## Architecture

```
           ┌────────────┐
           │  Dataset   │  (public, via `datasets`)
           └─────┬──────┘
                 │
            Bronze (raw)
                 │  DuckDB register
                 ▼
            Silver (clean)
                 │  type / rename / dedupe
                 ▼
      Gold (star schema)
       ┌────┼─────┼────┐
       ▼    ▼     ▼    ▼
     fact  dim  dim   dim
       └────┬─────┬────┘
            ▼     ▼
         QA checks
            │
            ▼
         Marts (BI)
            │
            ▼
         Charts
```

## Tech

- **Python 3.11**, **uv** for env management
- **DuckDB** for local SQL on in-memory tables
- **Pandas** for dataframe work
- **Matplotlib** for charts
- **JupyterLab** as the workbench
- **Docker** (optional) for a portable JupyterLab container

## Quick start

```bash
# 1. Install deps (creates .venv)
uv sync

# 2. Optional: override dataset
cp .env.example .env

# 3. Launch JupyterLab on http://localhost:8888
make dev
```

Open `data_engineering.ipynb` and run the cells top to bottom.

### With Docker

```bash
make build
make up        # JupyterLab on http://localhost:8888
make down
```

### Smoke test (executes the whole notebook headless)

```bash
make smoke
```

## Repository structure

```
data-engineering-medallion/
├── data_engineering.ipynb    ← the workshop notebook
├── smoke_test.sh             ← runs the notebook headless via nbconvert
├── pyproject.toml            ← uv-managed dependencies
├── uv.lock                   ← locked versions (committed)
├── Makefile                  ← dev / smoke / build / up / down
├── Dockerfile                ← python:3.11-slim + jupyterlab
├── docker-compose.yml        ← single `notebook` service on :8888
├── CLAUDE.md                 ← guidance for Claude Code
└── README.md
```

## Swap in your own dataset

The notebook loads a public dataset via Hugging Face `datasets`. To use your own:

```python
import pandas as pd, duckdb
df = pd.read_csv("your_data.csv")  # or parquet, or API response
con = duckdb.connect()
con.register("bronze_source", df)
```

Then update the Silver / Gold SQL to reflect your columns. The QA + marts + charts layers keep working.

## Progression

After this workshop, move on to:

- **`data-engineering-pipeline`** — intermediate: Airflow + Spark + Postgres + MinIO + Great Expectations + a Python FastAPI backend.
- **`end-to-end-data-pipeline`** — production: the full 20-service platform including Kafka, Snowflake, MLflow, Prometheus, Grafana, Kubernetes, Terraform, and Helm.

## Learn more

- Start the course: [learnwithparam.com/courses/data-engineering-medallion](https://www.learnwithparam.com/courses/data-engineering-medallion)
- Data Engineering Bootcamp: [learnwithparam.com/data-engineering-bootcamp](https://www.learnwithparam.com/data-engineering-bootcamp)
- All courses: [learnwithparam.com/courses](https://www.learnwithparam.com/courses)


## License

MIT. See `LICENSE`.
