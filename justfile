# Task runner — run `just` (no args) to list everything.
set shell := ["bash", "-cu"]

default:
    @just --list

# Resolve + install the locked environment (creates uv.lock and .venv)
sync:
    uv sync --all-extras --dev

# Add a runtime dependency, e.g. `just add duckdb`
add +pkgs:
    uv add {{pkgs}}

# Add a dev-only dependency, e.g. `just add-dev nbqa`
add-dev +pkgs:
    uv add --dev {{pkgs}}

# Lint with ruff (autofixes safe issues)
lint:
    uv run ruff check --fix .

# Format with ruff
fmt:
    uv run ruff format .

# Static type-check (mypy, stable)
typecheck:
    uv run mypy src

# Bleeding-edge type-check with Astral `ty` — no install, fetched on demand
typecheck-fast:
    uvx ty check

# Lint code *inside* notebooks
lint-nb:
    uv run nbqa ruff notebooks --fix

# Run the test suite with coverage
test:
    uv run pytest

# Run every pre-commit hook against all files
check:
    uv run pre-commit run --all-files

# Install the git pre-commit hooks
hooks:
    uv run pre-commit install --install-hooks

# Launch JupyterLab (http://localhost:8888)
lab:
    uv run jupyter lab --ip 0.0.0.0 --no-browser --ServerApp.token=''

# Launch a reactive marimo notebook (http://localhost:2718)
marimo:
    uv run marimo edit --host 0.0.0.0 --no-token

# Drop into an IPython REPL inside the environment
repl:
    uv run ipython
