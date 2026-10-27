# Charts for the Olist late-delivery project.
# SQL already did the joins, the late definition, and the ranks.
# This file only pulls those query results into pandas and draws three charts.
# The password stays in .env so it does not sit in this file.

from pathlib import Path
import os

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from dotenv import load_dotenv
from sqlalchemy import create_engine

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env")
engine = create_engine(os.environ["DATABASE_URL"])

sns.set_theme(style="whitegrid", font_scale=1.1)
plt.rcParams["figure.facecolor"] = "white"


def read_sql_file(name):
    # PostgreSQL ignores -- comments. Explanations stay in the .sql files.
    sql = (ROOT / "sql" / name).read_text(encoding="utf-8")
    return pd.read_sql(sql, engine)


def main():
    states = read_sql_file("02_late_by_state.sql")
    print(states.head(10).to_string(index=False))

    # Worst 10, plus SP so I can compare the northeast to a normal state.
    top_states = pd.concat(
        [states.head(10), states[states["customer_state"] == "SP"]]
    ).drop_duplicates("customer_state")
    fig, ax = plt.subplots(figsize=(9, 6))
    sns.barplot(
        data=top_states,
        x="late_rate_pct",
        y="customer_state",
        color="#c44e52",
        ax=ax,
    )
    ax.set_xlabel("Late deliveries (%)")
    ax.set_ylabel("Customer state")
    ax.set_title("Northeast states wait longer than São Paulo")
    fig.tight_layout()
    fig.savefig(ROOT / "figures" / "late_rate_by_state.png", dpi=160)
    plt.close(fig)

    categories = read_sql_file("03_late_by_category.sql")
    print(categories.head(10).to_string(index=False))

    top_cats = categories.head(12)
    fig, ax = plt.subplots(figsize=(9, 6))
    sns.barplot(
        data=top_cats,
        x="late_rate_pct",
        y="category",
        color="#4c72b0",
        ax=ax,
    )
    ax.set_xlabel("Late deliveries (%)")
    ax.set_ylabel("Product category")
    ax.set_title("Audio and electronics are late more often than housewares")
    fig.tight_layout()
    fig.savefig(ROOT / "figures" / "late_rate_by_category.png", dpi=160)
    plt.close(fig)

    reviews = read_sql_file("04_late_vs_reviews.sql")
    print(reviews.to_string(index=False))

    plot_df = reviews.copy()
    plot_df["delivery"] = plot_df["delivery"].replace({"late": "Late", "on_time": "On time"})

    fig, ax = plt.subplots(figsize=(7, 5))
    sns.barplot(
        data=plot_df,
        x="delivery",
        y="avg_review_score",
        hue="delivery",
        palette={"Late": "#c44e52", "On time": "#55a868"},
        legend=False,
        ax=ax,
    )
    ax.set_xlabel("")
    ax.set_ylabel("Average review score (1–5)")
    ax.set_ylim(0, 5)
    ax.set_title("Late orders are rated almost 2 stars lower")
    fig.tight_layout()
    fig.savefig(ROOT / "figures" / "review_score_late_vs_ontime.png", dpi=160)
    plt.close(fig)


if __name__ == "__main__":
    main()
