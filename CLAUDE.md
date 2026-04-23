# CLAUDE.md

Guidance for Claude Code when working in this repo.

## What this is

Beginner-level data engineering workshop for [learnwithparam.com](https://www.learnwithparam.com). Single Jupyter notebook walking through the medallion pattern (Bronze → Silver → Gold → QA → Marts) with DuckDB + Pandas. See `README.md` for the full walkthrough.

## Quick start

```bash
uv sync                # install deps
cp .env.example .env   # optional: override DATASET_NAME
make dev               # launches JupyterLab on :8888
```

## Smoke test

This repo does NOT use the shared `../smoke_test_all.sh` sweep (that's FastAPI-on-8111). It has its own:

```bash
make smoke             # or: bash smoke_test.sh
```

Expected: the notebook runs end-to-end headless and produces `/tmp/medallion_smoke_out.ipynb`.

## Push workflow

Before every push:

1. Run `make smoke`. It must pass.
2. Verify `.gitignore` covers `.env`, `__pycache__/`, `.venv/`, `.ipynb_checkpoints/`, generated data.
3. `git status` — confirm no tracked secrets or local scratch files.
4. Commit with a descriptive message.
5. `git push origin main` — remote is `git@github.com:learnwithparam/data-engineering-medallion.git`.

Never force-push. Never commit `.env` or populated data directories.
