# Data Science Dev Container

A portable, batteries-included **VS Code / containers.dev** environment for data
analysis. Open the folder, "Reopen in Container", and you get a fully reproducible
stack with no host setup beyond Docker.

> Self-contained and codebase-agnostic — copy the whole folder (including the
> dotfiles) into any project to bootstrap it.

## Quick start

1. Install **Docker Desktop** (Windows/macOS) or Docker/Podman (Linux) + the VS
   Code **Dev Containers** extension (`ms-vscode-remote.remote-containers`).
   The default config is **Dockerfile-based — no `docker compose` required**.
2. Open this folder in VS Code → **"Reopen in Container"**.
   (If prompted, pick **"Data Science (uv · ruff · polars · duckdb)"** — the
   plain Dockerfile config. A Compose variant is also offered; see below.)
3. Wait for the one-time build, then:

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
│   ├── devcontainer.json     # DEFAULT: Dockerfile-based, no Compose (Windows-friendly)
│   ├── Dockerfile            # base + uv + native libs + CPython + venv baked at build
│   ├── postCreate.sh         # kernel registration, ./.venv symlink, git hooks
│   ├── compose.yaml          # optional Compose variant: build, mounts, env, secrets
│   ├── compose.podman.yaml   # Compose: rootless-Podman override (userns keep-id)
│   └── compose/
│       └── devcontainer.json # optional "… (Compose)" config (shown in the picker)
├── notebooks/00-welcome.ipynb
├── src/ds_workspace/         # importable, testable helpers
├── tests/                    # pytest smoke tests
├── data/                     # git-ignored local data (placeholder ships)
├── pyproject.toml            # deps, extras, ruff/mypy/pytest config
├── .gitattributes            # force LF endings — Windows-safe shell scripts
├── .pre-commit-config.yaml
└── justfile                  # task shortcuts
```

## Container engine & variants

Two ways to run it — VS Code shows a picker on "Reopen in Container":

1. **Dockerfile (default, recommended).** Just `devcontainer.json`, **no Docker
   Compose required**. Works out of the box on Windows / macOS / Linux with
   Docker Desktop, Podman, or Rancher Desktop. Mounts, ports and env are set
   directly in `devcontainer.json`.
2. **Compose** (`.devcontainer/compose/devcontainer.json`). Use this if you want
   compose-managed secrets or plan to add more services; runtime lives in
   `compose.yaml`.

- **Environment** — Dockerfile variant: `containerEnv` in `devcontainer.json`.
  Compose variant: `environment:` + an optional `../.env` (copy `.env.example`).
- **Secrets** — Compose variant has a `secrets:` block (mounted at
  `/run/secrets/<name>`, never baked into an image layer). For the Dockerfile
  variant, mount a file via `mounts`.
- **Ports** — both only **forward** (never hard-publish) via `forwardPorts`, so
  VS Code auto-picks a free local port and rebuilds never hit "port already
  allocated".

### Windows notes

- Use **Docker Desktop** (WSL2 backend) — the default config needs no
  `docker compose`. Podman Desktop / Rancher Desktop work too.
- `.gitattributes` forces **LF** line endings so `postCreate.sh` runs inside the
  Linux container (CRLF would break it with `$'\r': command not found`). If you
  cloned *before* `.gitattributes` existed, normalize once:
  `git add --renormalize . && git checkout .` (or just re-clone).

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

So bind-mounted files stay writable, map the container user to your host UID:

- **Dockerfile variant** — uncomment in `devcontainer.json`:
  ```jsonc
  "runArgs": ["--userns=keep-id"]
  ```
- **Compose variant** — list both files in the Compose config's
  `dockerComposeFile` (Compose ignores `runArgs`, so the override carries it):
  ```jsonc
  "dockerComposeFile": ["../compose.yaml", "../compose.podman.yaml"]
  ```
  `compose.podman.yaml` adds `userns_mode: keep-id` + `security_opt:
  [label=disable]` (SELinux hosts).

On Docker / Docker Desktop, leave both off.

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
