# syntax=docker/dockerfile:1

# Debian-based dev-container base (non-root `vscode` user, git, zsh, sudo).
FROM mcr.microsoft.com/devcontainers/base:bookworm

# --- uv: ultra-fast Python package & project manager (Astral, written in Rust) ---
# Copying the static binary from the official image is the fastest, most
# reproducible way to get uv + uvx into any base image.
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Native libraries occasionally needed when building wheels in the data stack.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        build-essential \
        graphviz \
        libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ARG PYTHON_VERSION=3.13

# Shared, world-readable locations so BOTH root (at build) and vscode (at
# runtime) resolve the *same* managed interpreter. Otherwise uv would look in
# the wrong per-user dir at first open and try to re-download CPython — which
# breaks on locked-down/offline networks.
ENV UV_LINK_MODE=copy \
    UV_PYTHON_PREFERENCE=managed \
    UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_PROJECT_ENVIRONMENT=/home/vscode/.venv \
    PATH=/home/vscode/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# 1) Install the managed CPython into the shared dir.
RUN uv python install "${PYTHON_VERSION}"

# 2) Build the project virtualenv AT BUILD TIME, where the network is available.
#    Installing at the canonical workspace path means the editable install of
#    the local package still resolves once the project is bind-mounted there at
#    runtime — so opening the container needs no internet at all.
WORKDIR /workspaces/data-science
COPY pyproject.toml README.md .python-version ./
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --all-extras --dev

# Hand the baked interpreter + venv to the non-root user.
RUN chown -R vscode:vscode /home/vscode/.venv /opt/uv
