"""Smoke tests — confirm the core stack imports and the engines talk to each other."""

from __future__ import annotations

import duckdb
import polars as pl


def test_polars_roundtrip() -> None:
    df = pl.DataFrame({"x": [1, 2, 3], "y": [10, 20, 30]})
    assert df.select(pl.col("y").sum()).item() == 60


def test_duckdb_queries_polars() -> None:
    """DuckDB can query a Polars DataFrame in-process, zero-copy via Arrow."""
    df = pl.DataFrame({"n": [1, 2, 3, 4]})  # noqa: F841 — referenced by name in SQL
    total = duckdb.sql("select sum(n) as total from df").pl().item()
    assert total == 10
