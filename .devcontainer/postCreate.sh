#!/usr/bin/env bash
# Runs once, as the `vscode` user, after the container is created.
# The Python environment is baked into the image at BUILD time, so this script
# needs no network — it only wires up the Jupyter kernel and git hooks.
# (Using the venv binaries directly avoids `uv run`, which would try to re-sync.)
set -euo pipefail

# The uv cache volume is mounted root-owned on first use — claim it.
sudo chown -R vscode:vscode /home/vscode/.cache 2>/dev/null || true

# The venv lives at /home/vscode/.venv (outside the bind-mounted workspace so it
# survives the mount). Surface it as ./.venv so the Python & Jupyter extensions
# auto-discover it — otherwise they offer to download a fresh interpreter via uv.
if [ ! -L .venv ] && [ ! -d .venv ]; then
  ln -s /home/vscode/.venv .venv
fi

echo "▶ Registering the Jupyter kernel…"
python -m ipykernel install --user \
  --name "ds-uv" \
  --display-name "Python (uv · data-science)"

echo "▶ Installing pre-commit git hooks (best-effort; needs network)…"
if ! pre-commit install --install-hooks >/dev/null 2>&1; then
  echo "  (skipped — no git repo yet, or no network to fetch hook repos)"
fi

cat <<'EOF'

✅ Dev container ready — environment was baked at build time, no network needed.

   just lab        launch JupyterLab        (http://localhost:8888)
   just marimo     launch a reactive marimo (http://localhost:2718)
   just lint       ruff check --fix
   just test       pytest + coverage

   Changed dependencies in pyproject.toml? run:  just sync   (needs network)

EOF
