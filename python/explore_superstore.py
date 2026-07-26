"""Executa uma exploração inicial do dataset Superstore."""

from pathlib import Path

import pandas as pd


DATASET_PATH = Path(__file__).resolve().parents[2] / "data" / "superstore.csv"


def main() -> None:
    """Carrega o CSV e exibe informações básicas para validação."""
    dataframe = pd.read_csv(DATASET_PATH, encoding="cp1252")

    print("Colunas:")
    print(dataframe.columns.tolist())
    print("\nAmostra:")
    print(dataframe.head())
    print("\nResumo estatístico:")
    print(dataframe.describe(include="all"))
    print("\nValores não nulos por coluna:")
    print(dataframe.count())


if __name__ == "__main__":
    main()
