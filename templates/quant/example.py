"""Market data lives in ~/dat/mkt as parquet: fetch with `mkt hist SPY`."""
from pathlib import Path

import polars as pl

DATA = Path.home() / "dat" / "mkt"


def load(symbol: str) -> pl.DataFrame:
    return pl.read_parquet(DATA / f"{symbol}.parquet").sort("date")


if __name__ == "__main__":
    df = load("SPY").with_columns(ret=pl.col("adjclose").pct_change())
    print(df.tail())
    print(f"annualised vol: {df['ret'].std() * 252**0.5:.1%}")
