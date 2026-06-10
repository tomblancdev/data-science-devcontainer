"""Reusable helpers for the workspace.

Put functions you want to import from notebooks *and* tests here, e.g.::

    from ds_workspace import load_csv

so logic lives in one tested place instead of being copy-pasted across cells.
"""

from __future__ import annotations

from pathlib import Path

import polars as pl

__all__ = ["DATA_DIR", "load_csv"]

# Project-root-relative data directory (kept out of git by default).
DATA_DIR = Path(__file__).resolve().parents[2] / "data"


def load_csv(name: str, **kwargs: object) -> pl.DataFrame:
    """Load ``data/<name>`` into a Polars DataFrame.

    Args:
        name: File name (or relative path) under ``DATA_DIR``.
        **kwargs: Forwarded to :func:`polars.read_csv`.

    Returns:
        The parsed DataFrame.
    """
    return pl.read_csv(DATA_DIR / name, **kwargs)  # type: ignore[arg-type]
