# Data Science Dev Container

A portable, batteries-included **VS Code / containers.dev** environment for data
analysis. Open the folder, "Reopen in Container", and you get a fully reproducible
stack with no host setup beyond Docker.

> Self-contained and codebase-agnostic — copy the whole folder (including the
> dotfiles) into any project to bootstrap it.

## Quick start

1. Install **Docker** + the VS Code **Dev Containers** extension
   (`ms-vscode-remote.remote-containers`).
2. Open this folder in VS Code → **"Reopen in Container"**.
3. Wait for the one-time build + `uv sync`, then:

   ```bash
   just            # list all tasks
   just lab        # JupyterLab    → http://localhost:8888
   just marimo     # reactive nb   → http://localhost:2718
   just test       # pytest + coverage
   ```

4. Open `notebooks/00-welcome.ipynb` and pick the **`Python (uv · data-science)`** kernel.

## Why these tools (the "new tech")

| Concern            | Choice                     | Why it's best-in-class                                            |
| ------------------ | -------------------------- | ---------------------------------------------------------------- |
| Packages + Python  | **uv** (Astral)            | 10–100× faster than pip/poetry; installs & pins CPython; `uv.lock` for reproducibility |
| Lint + format      | **ruff** (Astral)          | One Rust tool replacing black + flake8 + isort + pylint; fix-on-save |
| Type check         | **mypy** + **`uvx ty`**    | Stable mypy, plus Astral's new Rust checker `ty` on demand (no install) |
| Dataframes         | **Polars** + **narwhals**  | Multithreaded, lazy, Arrow-native; narwhals lets code target Polars *or* pandas |
| SQL / analytics    | **DuckDB**                 | In-process OLAP over CSV/Parquet/Arrow; queries a Polars df zero-copy |
| Notebooks          | **Jupyter** + **marimo**   | Classic `.ipynb` in VS Code, plus reactive git-friendly `.py` notebooks |
| Explore visually   | **Data Wrangler**          | Point-and-click profiling/cleaning that emits Polars/pandas code |
| Task runner        | **just**                   | Discoverable, dependency-free command shortcuts (`justfile`)     |
| Clean diffs        | **nbstripout** + jupytext  | Strip outputs / pair notebooks to `.py` so reviews stay readable |

## Layout

```
.
├── .devcontainer/
│   ├── devcontainer.json    # VS Code wiring: features, extensions, settings
│   ├── compose.yaml         # runtime: build, mounts, ports, env, secrets
│   ├── compose.podman.yaml  # opt-in rootless-Podman override (userns keep-id)
│   ├── Dockerfile           # base + uv + native libs + managed CPython
│   └── postCreate.sh        # uv sync, kernel registration, pre-commit
├── notebooks/00-welcome.ipynb
├── src/ds_workspace/       # importable, testable helpers
├── tests/                  # pytest smoke tests
├── data/                   # git-ignored local data
├── pyproject.toml          # deps, extras, ruff/mypy/pytest config
├── .pre-commit-config.yaml
└── justfile                # task shortcuts
```

## Container engine

The dev container is **Compose-based**: `compose.yaml` owns the build, bind
mounts, published ports, environment, and secrets. `devcontainer.json` only
wires up VS Code. (Note: because it uses Compose, `runArgs` is ignored — runtime
flags belong in the compose file.)

- **Environment** — `compose.yaml` reads an optional `../.env` (copy
  `.env.example` → `.env`).
- **Secrets** — uncomment the `secrets:` blocks in `compose.yaml`; the file is
  mounted read-only at `/run/secrets/<name>` and never lands in an image layer.
- **Ports** — `compose.yaml` only `expose`s them (no host bind); VS Code
  forwards them via `forwardPorts` in `devcontainer.json` and auto-picks a free
  local port if one's taken. This avoids "port already allocated" errors on
  rebuild and clashes with other running stacks.

### Networking: build vs. runtime

The whole Python environment (managed CPython **and** all packages) is installed
**at image-build time** by the `Dockerfile`, into `/home/vscode/.venv`. Opening
the container then needs **no internet** — `postCreate` only registers the
Jupyter kernel and git hooks.

- **Restricted runtime network?** You're fine — nothing is downloaded on open.
  `UV_PYTHON_DOWNLOADS=never` makes uv fail fast (clear message) instead of
  hanging if anything ever probes for a download.
- **Restricted build network (proxy)?** Export `HTTP_PROXY` / `HTTPS_PROXY` /
  `NO_PROXY` before "Rebuild Container" (or set them in `.env`); they flow into
  the build for apt + uv.
- **Changed dependencies?** Edit `pyproject.toml`, then `just sync` (needs
  network once) or rebuild the container.

> Why this matters: a common failure is uv trying to download CPython/packages
> *on first open*, which dies on locked-down networks. Baking everything at
> build time — where the network is usually open — avoids that entirely.

### Running on Podman (rootless)

`--userns=keep-id` can't go through `runArgs` (Compose ignores it), and
`userns_mode: keep-id` is Podman-only (Docker rejects it), so it lives in an
opt-in override. Enable it by listing both files in `devcontainer.json`:

```jsonc
"dockerComposeFile": ["compose.yaml", "compose.podman.yaml"]
```

`compose.podman.yaml` adds `userns_mode: keep-id` (maps the container user to
your host UID so bind-mounted files stay writable) plus `security_opt:
[label=disable]` for SELinux hosts. On Docker, just leave it out.

## Common tweaks

- **Python version** — edit `.python-version` and the `PYTHON_VERSION` build arg
  in `devcontainer.json`.
- **Add a library** — `just add <pkg>` (runtime) or `just add-dev <pkg>` (tooling);
  the lockfile updates automatically.
- **Optional extras** — `ml`, `db`, `geo` are defined in `pyproject.toml`
  (installed by default via `uv sync --all-extras`; trim as needed).
- **AI assistant** — none is bundled. Add one to `extensions` in
  `devcontainer.json` if you want it, e.g. `Continue.continue` (model-agnostic:
  Claude, GPT, local Ollama) or `GitHub.copilot`.
