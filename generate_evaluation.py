"""
Aura Habit Tracker — User Evaluation Analysis
Generates LaTeX chapter + publication-quality charts from survey data.
For BSc Computing Science dissertation at Heriot-Watt University Malaysia.
"""

import os
import re
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.colors import LinearSegmentedColormap

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
EXCEL_FILE = os.path.join(PROJECT_DIR, "Aura Evaluation Survey(1-20) (1).xlsx")
OUTPUT_DIR = os.path.join(PROJECT_DIR, "evaluation")
CHARTS_DIR = os.path.join(OUTPUT_DIR, "charts")
LATEX_FILE = os.path.join(OUTPUT_DIR, "evaluation.tex")

LIKERT_MAP = {
    "Strongly disagree": 1,
    "Disagree": 2,
    "Neutral": 3,
    "Agree": 4,
    "Strongly agree": 5,
}

FEATURE_NAMES = [
    "Habit Tracking",
    "AI Coach",
    "Reminders",
    "Analytics Dashboard",
    "Gamification",
    "Visual Design",
    "Navigation",
    "Clarity \\& Readability",
]

FEATURE_NAMES_PLAIN = [
    "Habit Tracking",
    "AI Coach",
    "Reminders",
    "Analytics Dashboard",
    "Gamification",
    "Visual Design",
    "Navigation",
    "Clarity & Readability",
]

SATISFACTION_LABELS = {
    1: "Very Dissatisfied",
    2: "Dissatisfied",
    3: "Neutral",
    4: "Satisfied",
    5: "Very Satisfied",
}

# Colour palette
COLORS = {
    "primary": "#4A90D9",
    "secondary": "#7B68EE",
    "accent": "#50C878",
    "warning": "#F4A460",
    "danger": "#E8706A",
    "neutral": "#A9A9A9",
    "grade_a": "#2ECC71",
    "grade_b": "#3498DB",
    "grade_c": "#F1C40F",
    "grade_d": "#E67E22",
    "grade_f": "#E74C3C",
    "rating_5": "#2ECC71",
    "rating_4": "#82D99E",
    "rating_3": "#F1C40F",
    "rating_2": "#E8956A",
    "rating_1": "#E74C3C",
}

SUS_QUESTIONS = [
    "I think that I would like to use Aura frequently.",
    "I found Aura unnecessarily complex.",
    "I thought Aura was easy to use.",
    "I think that I would need the support of a technical person to be able to use Aura.",
    "I found the various functions in Aura were well integrated.",
    "I thought there was too much inconsistency in Aura.",
    "I would imagine that most people would learn to use Aura very quickly.",
    "I found Aura very cumbersome to use.",
    "I felt very confident using Aura.",
    "I needed to learn a lot of things before I could get going with Aura.",
]

# Qualitative theme keywords
LIKED_THEMES = {
    "AI Coach & Personalisation": [
        "ai", "coach", "personali", "suggestion", "insight", "score", "feedback",
        "accurate", "relevant",
    ],
    "UI/UX Design": [
        "ui", "design", "clean", "minimal", "colour", "color", "dark mode",
        "aesthetic", "visual", "look",
    ],
    "Gamification & Streaks": [
        "streak", "badge", "achievement", "heatmap", "gamif", "accountable",
    ],
    "Tracking & Goals": [
        "track", "goal", "categor", "progress", "time-based", "count-based",
        "habit", "balanced",
    ],
    "Data & Integration": [
        "apple health", "data export", "export", "information", "control",
        "data", "reinstall",
    ],
    "Onboarding & Ease of Use": [
        "onboarding", "smooth", "easy", "quickly", "set up", "two minutes",
    ],
    "Notifications & Reminders": [
        "reminder", "notification", "well-timed", "not annoying",
    ],
}

SUGGESTION_THEMES = {
    "New Features": [
        "widget", "pause", "reorder", "social", "friend", "calendar view",
        "monthly", "notes", "journal", "routine", "habit-free", "rest day",
        "group", "ring",
    ],
    "AI Enhancements": [
        "ai", "fine-tune", "action item", "ai request", "schedule",
        "ai actions",
    ],
    "UI/UX Improvements": [
        "heatmap", "colour", "color", "shades", "progress ring",
        "estimated time", "simplif", "home screen",
    ],
    "Information & Clarity": [
        "onboarding", "explain", "description", "clearer", "summary",
        "streak count", "notification",
    ],
}

# Matplotlib global style
plt.rcParams.update({
    "font.family": "serif",
    "font.size": 11,
    "axes.titlesize": 13,
    "axes.labelsize": 12,
    "figure.dpi": 300,
    "savefig.dpi": 300,
    "savefig.bbox": "tight",
    "figure.figsize": (8, 5),
})


# ---------------------------------------------------------------------------
# Data Loading
# ---------------------------------------------------------------------------
def load_data(path):
    df = pd.read_excel(path)
    cols = df.columns.tolist()

    # Identify column indices by position (0-indexed)
    # 0:ID, 1:Start, 2:Completion, 3:Email, 4:Name, 5:LastModified,
    # 6:Consent, 7:Age, 8:HWUM, 9:Experience,
    # 10-19: SUS Q1-Q10, 20-27: Features, 28:Satisfaction,
    # 29:Liked, 30:Suggestions

    # Parse SUS columns (Likert text -> int)
    sus_cols = cols[10:20]
    for c in sus_cols:
        df[c] = df[c].map(LIKERT_MAP)

    # Parse feature ratings ("5 - Excellent" -> 5)
    feature_cols = cols[20:28]
    for c in feature_cols:
        df[c] = df[c].apply(lambda v: int(str(v).split(" - ")[0]))

    # Parse satisfaction
    sat_col = cols[28]
    df[sat_col] = df[sat_col].apply(lambda v: int(str(v).split(" - ")[0]))

    # Extract short experience level
    exp_col = cols[9]
    df["experience_short"] = df[exp_col].apply(
        lambda v: str(v).split("(")[0].strip() if pd.notna(v) else "Unknown"
    )

    # Store column name references
    df.attrs["sus_cols"] = sus_cols
    df.attrs["feature_cols"] = feature_cols
    df.attrs["sat_col"] = sat_col
    df.attrs["age_col"] = cols[7]
    df.attrs["exp_col"] = cols[9]
    df.attrs["liked_col"] = cols[29]
    df.attrs["suggestions_col"] = cols[30]

    return df


# ---------------------------------------------------------------------------
# Analysis Functions
# ---------------------------------------------------------------------------
def compute_sus_scores(df):
    sus_cols = df.attrs["sus_cols"]
    scores = []
    raw_items = []

    for _, row in df.iterrows():
        adjusted = []
        for i, c in enumerate(sus_cols):
            val = row[c]
            q_num = i + 1  # Q1-Q10
            if q_num % 2 == 1:  # odd: positive
                adjusted.append(val - 1)
            else:  # even: negative
                adjusted.append(5 - val)
        sus_score = sum(adjusted) * 2.5
        scores.append(sus_score)
        raw_items.append(adjusted)

    scores_arr = np.array(scores)

    # Adjective rating (Bangor et al., 2009)
    mean_score = float(np.mean(scores_arr))
    if mean_score >= 84.1:
        adjective = "Best Imaginable"
    elif mean_score >= 80.3:
        adjective = "Excellent"
    elif mean_score >= 68.0:
        adjective = "Good"
    elif mean_score >= 51.0:
        adjective = "OK"
    elif mean_score >= 25.1:
        adjective = "Poor"
    else:
        adjective = "Worst Imaginable"

    # Grade
    if mean_score > 80.3:
        grade = "A"
    elif mean_score >= 68.0:
        grade = "B"
    elif mean_score >= 51.0:
        grade = "C"
    elif mean_score >= 25.1:
        grade = "D"
    else:
        grade = "F"

    # Acceptability
    if mean_score > 70:
        acceptability = "Acceptable"
    elif mean_score >= 50:
        acceptability = "Marginal"
    else:
        acceptability = "Not Acceptable"

    # Per-experience-level means
    exp_sus = {}
    for exp in df["experience_short"].unique():
        mask = df["experience_short"] == exp
        exp_scores = scores_arr[mask.values]
        exp_sus[exp] = {
            "mean": float(np.mean(exp_scores)),
            "std": float(np.std(exp_scores, ddof=1)) if len(exp_scores) > 1 else 0.0,
            "n": int(len(exp_scores)),
        }

    # Individual grade per respondent
    individual_grades = []
    for s in scores:
        if s > 80.3:
            individual_grades.append("A")
        elif s >= 68.0:
            individual_grades.append("B")
        elif s >= 51.0:
            individual_grades.append("C")
        elif s >= 25.1:
            individual_grades.append("D")
        else:
            individual_grades.append("F")

    return {
        "scores": scores,
        "raw_items": raw_items,
        "mean": mean_score,
        "median": float(np.median(scores_arr)),
        "std": float(np.std(scores_arr, ddof=1)),
        "min": float(np.min(scores_arr)),
        "max": float(np.max(scores_arr)),
        "adjective": adjective,
        "grade": grade,
        "acceptability": acceptability,
        "by_experience": exp_sus,
        "individual_grades": individual_grades,
    }


def analyze_feature_ratings(df):
    feature_cols = df.attrs["feature_cols"]
    results = {}
    for i, c in enumerate(feature_cols):
        vals = df[c].values
        dist = {r: int(np.sum(vals == r)) for r in range(1, 6)}
        results[FEATURE_NAMES_PLAIN[i]] = {
            "mean": float(np.mean(vals)),
            "median": float(np.median(vals)),
            "std": float(np.std(vals, ddof=1)),
            "distribution": dist,
        }

    # Rank by mean
    ranked = sorted(results.items(), key=lambda x: x[1]["mean"], reverse=True)
    for rank, (name, data) in enumerate(ranked, 1):
        data["rank"] = rank

    return results


def analyze_demographics(df):
    age_col = df.attrs["age_col"]
    age_counts = df[age_col].value_counts()
    age_order = ["18\u201324", "25\u201334", "35\u201344", "45\u201354", "55 or above"]
    age_dist = {a: int(age_counts.get(a, 0)) for a in age_order}

    exp_counts = df["experience_short"].value_counts()
    exp_order = ["Beginner", "Intermediate", "Advanced"]
    exp_dist = {e: int(exp_counts.get(e, 0)) for e in exp_order}

    n = len(df)
    return {
        "age": age_dist,
        "age_pct": {k: round(v / n * 100, 1) for k, v in age_dist.items()},
        "experience": exp_dist,
        "experience_pct": {k: round(v / n * 100, 1) for k, v in exp_dist.items()},
        "n": n,
    }


def analyze_satisfaction(df):
    sat_col = df.attrs["sat_col"]
    vals = df[sat_col].values
    dist = {r: int(np.sum(vals == r)) for r in range(1, 6)}
    n = len(vals)
    return {
        "mean": float(np.mean(vals)),
        "median": float(np.median(vals)),
        "std": float(np.std(vals, ddof=1)),
        "distribution": dist,
        "distribution_pct": {k: round(v / n * 100, 1) for k, v in dist.items()},
    }


def _classify_themes(text, theme_map):
    """Return list of matching theme names for a text response."""
    text_lower = str(text).lower()
    matched = []
    for theme, keywords in theme_map.items():
        for kw in keywords:
            if kw in text_lower:
                matched.append(theme)
                break
    return matched


def analyze_qualitative(df):
    liked_col = df.attrs["liked_col"]
    suggestions_col = df.attrs["suggestions_col"]

    # Classify liked responses
    liked_themes = {t: {"count": 0, "quotes": []} for t in LIKED_THEMES}
    for _, row in df.iterrows():
        text = str(row[liked_col])
        matched = _classify_themes(text, LIKED_THEMES)
        for t in matched:
            liked_themes[t]["count"] += 1
            if len(liked_themes[t]["quotes"]) < 2:
                liked_themes[t]["quotes"].append(text)

    # Classify suggestion responses
    suggestion_themes = {t: {"count": 0, "quotes": []} for t in SUGGESTION_THEMES}
    for _, row in df.iterrows():
        text = str(row[suggestions_col])
        matched = _classify_themes(text, SUGGESTION_THEMES)
        for t in matched:
            suggestion_themes[t]["count"] += 1
            if len(suggestion_themes[t]["quotes"]) < 2:
                suggestion_themes[t]["quotes"].append(text)

    # Sort by count descending
    liked_sorted = dict(
        sorted(liked_themes.items(), key=lambda x: x[1]["count"], reverse=True)
    )
    suggestion_sorted = dict(
        sorted(suggestion_themes.items(), key=lambda x: x[1]["count"], reverse=True)
    )

    return {"liked": liked_sorted, "suggestions": suggestion_sorted}


# ---------------------------------------------------------------------------
# Chart Generation
# ---------------------------------------------------------------------------
def _save_chart(fig, name):
    fig.savefig(os.path.join(CHARTS_DIR, f"{name}.png"))
    fig.savefig(os.path.join(CHARTS_DIR, f"{name}.pdf"))
    plt.close(fig)


def chart_sus_distribution(sus):
    fig, ax = plt.subplots(figsize=(8, 5))
    scores = sus["scores"]

    # Acceptability bands
    ax.axvspan(0, 50, alpha=0.08, color=COLORS["danger"], label="Not Acceptable")
    ax.axvspan(50, 70, alpha=0.08, color=COLORS["warning"], label="Marginal")
    ax.axvspan(70, 100, alpha=0.08, color=COLORS["accent"], label="Acceptable")

    # Histogram
    bins = np.arange(40, 105, 5)
    ax.hist(scores, bins=bins, color=COLORS["primary"], edgecolor="white",
            alpha=0.85, zorder=3)

    # Mean line
    ax.axvline(sus["mean"], color=COLORS["danger"], linestyle="--", linewidth=2,
               label=f'Mean = {sus["mean"]:.1f}', zorder=4)

    ax.set_xlabel("SUS Score")
    ax.set_ylabel("Number of Respondents")
    ax.set_title("Distribution of SUS Scores")
    ax.legend(loc="upper left", fontsize=9)
    ax.set_xlim(35, 105)
    ax.yaxis.set_major_locator(plt.MaxNLocator(integer=True))
    ax.grid(axis="y", alpha=0.3)

    _save_chart(fig, "sus_distribution")


def chart_sus_individual(sus):
    n = len(sus["scores"])
    fig, ax = plt.subplots(figsize=(8, max(5, n * 0.35)))
    labels = [f"R{i+1}" for i in range(n)]
    grade_colors = {
        "A": COLORS["grade_a"],
        "B": COLORS["grade_b"],
        "C": COLORS["grade_c"],
        "D": COLORS["grade_d"],
        "F": COLORS["grade_f"],
    }
    bar_colors = [grade_colors[g] for g in sus["individual_grades"]]

    y_pos = np.arange(n)
    bars = ax.barh(y_pos, sus["scores"], color=bar_colors, edgecolor="white",
                   height=0.7, zorder=3)

    # Label bars with score
    for bar, score in zip(bars, sus["scores"]):
        ax.text(bar.get_width() + 1, bar.get_y() + bar.get_height() / 2,
                f"{score:.1f}", va="center", fontsize=9)

    # Mean line
    ax.axvline(sus["mean"], color=COLORS["danger"], linestyle="--", linewidth=1.5,
               label=f'Mean = {sus["mean"]:.1f}')
    # 68 benchmark
    ax.axvline(68, color=COLORS["neutral"], linestyle=":", linewidth=1,
               label="SUS Benchmark (68)")

    ax.set_yticks(y_pos)
    ax.set_yticklabels(labels)
    ax.set_xlabel("SUS Score")
    ax.set_title("Individual SUS Scores by Respondent")
    ax.set_xlim(0, 105)
    ax.invert_yaxis()
    ax.legend(loc="lower right", fontsize=9)
    ax.grid(axis="x", alpha=0.3)

    # Legend patches for grades
    grade_patches = [mpatches.Patch(color=grade_colors[g], label=f"Grade {g}")
                     for g in ["A", "B", "C", "D", "F"]
                     if g in sus["individual_grades"]]
    ax.legend(handles=grade_patches + ax.get_legend_handles_labels()[0][-2:],
              loc="lower right", fontsize=8)

    _save_chart(fig, "sus_individual")


def chart_sus_adjective(sus):
    fig, ax = plt.subplots(figsize=(10, 3))

    # Define segments
    segments = [
        (0, 25.1, "Worst\nImaginable", COLORS["grade_f"]),
        (25.1, 51.0, "Poor", COLORS["grade_d"]),
        (51.0, 68.0, "OK", COLORS["grade_c"]),
        (68.0, 80.3, "Good", COLORS["grade_b"]),
        (80.3, 84.1, "Excellent", "#2980B9"),
        (84.1, 100, "Best\nImaginable", COLORS["grade_a"]),
    ]

    for start, end, label, color in segments:
        ax.barh(0, end - start, left=start, height=0.6, color=color,
                edgecolor="white", linewidth=1.5)
        mid = (start + end) / 2
        ax.text(mid, 0, label, ha="center", va="center", fontsize=8,
                fontweight="bold", color="white")

    # Grade scale below
    grade_segments = [
        (0, 25.1, "F"),
        (25.1, 51.0, "D"),
        (51.0, 68.0, "C"),
        (68.0, 80.3, "B"),
        (80.3, 100, "A"),
    ]
    for start, end, label in grade_segments:
        ax.barh(-0.8, end - start, left=start, height=0.4, color="#E0E0E0",
                edgecolor="white", linewidth=1)
        mid = (start + end) / 2
        ax.text(mid, -0.8, label, ha="center", va="center", fontsize=10,
                fontweight="bold")

    # Marker for Aura's score
    ax.annotate(f'Aura\n{sus["mean"]:.1f}',
                xy=(sus["mean"], 0.3), xytext=(sus["mean"], 1.2),
                fontsize=11, fontweight="bold", ha="center", color=COLORS["primary"],
                arrowprops=dict(arrowstyle="->", color=COLORS["primary"], lw=2))

    ax.set_xlim(0, 100)
    ax.set_ylim(-1.3, 2.0)
    ax.set_xlabel("SUS Score")
    ax.set_title("SUS Adjective Rating Scale with Aura's Position")
    ax.set_yticks([])
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_visible(False)

    _save_chart(fig, "sus_adjective_scale")


def chart_feature_comparison(features):
    ranked = sorted(features.items(), key=lambda x: x[1]["mean"])
    names = [n for n, _ in ranked]
    means = [d["mean"] for _, d in ranked]
    stds = [d["std"] for _, d in ranked]

    fig, ax = plt.subplots(figsize=(8, 5))
    y_pos = np.arange(len(names))
    bars = ax.barh(y_pos, means, xerr=stds, color=COLORS["primary"],
                   edgecolor="white", height=0.6, capsize=3, zorder=3)

    for bar, mean in zip(bars, means):
        ax.text(bar.get_width() + 0.15, bar.get_y() + bar.get_height() / 2,
                f"{mean:.2f}", va="center", fontsize=9)

    ax.set_yticks(y_pos)
    ax.set_yticklabels(names)
    ax.set_xlabel("Mean Rating (1\u20135)")
    ax.set_title("Feature Ratings Comparison (Ranked by Mean)")
    ax.set_xlim(0, 5.5)
    ax.grid(axis="x", alpha=0.3)

    _save_chart(fig, "feature_comparison")


def chart_feature_distribution(features):
    ranked = sorted(features.items(), key=lambda x: x[1]["mean"], reverse=True)
    names = [n for n, _ in ranked]
    n_respondents = sum(ranked[0][1]["distribution"].values())

    fig, ax = plt.subplots(figsize=(10, 5))
    rating_colors = [COLORS["rating_1"], COLORS["rating_2"], COLORS["rating_3"],
                     COLORS["rating_4"], COLORS["rating_5"]]
    rating_labels = ["1 - Very Poor", "2 - Poor", "3 - Average", "4 - Good",
                     "5 - Excellent"]

    y_pos = np.arange(len(names))
    for rating in range(1, 6):
        lefts = []
        widths = []
        for _, data in ranked:
            count = data["distribution"].get(rating, 0)
            pct = count / n_respondents * 100
            left = sum(
                data["distribution"].get(r, 0) / n_respondents * 100
                for r in range(1, rating)
            )
            lefts.append(left)
            widths.append(pct)
        ax.barh(y_pos, widths, left=lefts, height=0.6,
                color=rating_colors[rating - 1], edgecolor="white",
                label=rating_labels[rating - 1])

        # Label percentages if >= 10%
        for j, (w, l) in enumerate(zip(widths, lefts)):
            if w >= 10:
                ax.text(l + w / 2, y_pos[j], f"{w:.0f}%", ha="center",
                        va="center", fontsize=8, fontweight="bold", color="white")

    ax.set_yticks(y_pos)
    ax.set_yticklabels(names)
    ax.set_xlabel("Percentage of Respondents")
    ax.set_title("Feature Rating Distribution")
    ax.set_xlim(0, 100)
    ax.legend(loc="lower right", fontsize=8)

    _save_chart(fig, "feature_distribution")


def chart_demographics_age(demo):
    labels = []
    sizes = []
    for age, count in demo["age"].items():
        if count > 0:
            labels.append(age.replace("\u2013", "\u2013"))
            sizes.append(count)

    fig, ax = plt.subplots(figsize=(6, 5))
    colors = [COLORS["primary"], COLORS["secondary"], COLORS["accent"],
              COLORS["warning"], COLORS["neutral"]][:len(labels)]
    wedges, texts, autotexts = ax.pie(
        sizes, labels=labels, autopct=lambda p: f"{p:.1f}%\n(n={int(round(p*sum(sizes)/100))})",
        colors=colors, startangle=90, textprops={"fontsize": 10},
    )
    for t in autotexts:
        t.set_fontsize(9)
    ax.set_title("Respondent Age Distribution")

    _save_chart(fig, "demographics_age")


def chart_demographics_experience(demo):
    labels = []
    sizes = []
    for exp, count in demo["experience"].items():
        if count > 0:
            labels.append(exp)
            sizes.append(count)

    fig, ax = plt.subplots(figsize=(6, 5))
    colors = [COLORS["accent"], COLORS["primary"], COLORS["secondary"]][:len(labels)]
    wedges, texts, autotexts = ax.pie(
        sizes, labels=labels, autopct=lambda p: f"{p:.1f}%\n(n={int(round(p*sum(sizes)/100))})",
        colors=colors, startangle=90, textprops={"fontsize": 10},
    )
    for t in autotexts:
        t.set_fontsize(9)
    ax.set_title("Respondent Experience Level Distribution")

    _save_chart(fig, "demographics_experience")


def chart_satisfaction(sat):
    fig, ax = plt.subplots(figsize=(8, 5))
    ratings = list(range(1, 6))
    counts = [sat["distribution"].get(r, 0) for r in ratings]
    labels = [SATISFACTION_LABELS[r] for r in ratings]
    bar_colors = [COLORS["rating_1"], COLORS["rating_2"], COLORS["rating_3"],
                  COLORS["rating_4"], COLORS["rating_5"]]

    bars = ax.bar(ratings, counts, color=bar_colors, edgecolor="white",
                  width=0.6, zorder=3)
    for bar, count in zip(bars, counts):
        if count > 0:
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.2,
                    str(count), ha="center", va="bottom", fontsize=11,
                    fontweight="bold")

    ax.axvline(sat["mean"], color=COLORS["danger"], linestyle="--", linewidth=1.5,
               label=f'Mean = {sat["mean"]:.2f}')
    ax.set_xticks(ratings)
    ax.set_xticklabels(labels, rotation=20, ha="right", fontsize=9)
    ax.set_ylabel("Number of Respondents")
    ax.set_title("Overall Satisfaction Distribution")
    ax.yaxis.set_major_locator(plt.MaxNLocator(integer=True))
    ax.legend(fontsize=9)
    ax.grid(axis="y", alpha=0.3)

    _save_chart(fig, "satisfaction_distribution")


def chart_qualitative_themes(qual):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

    # Liked themes
    liked = {k: v for k, v in qual["liked"].items() if v["count"] > 0}
    liked_sorted = sorted(liked.items(), key=lambda x: x[1]["count"])
    if liked_sorted:
        names_l = [n for n, _ in liked_sorted]
        counts_l = [d["count"] for _, d in liked_sorted]
        ax1.barh(range(len(names_l)), counts_l, color=COLORS["accent"],
                 edgecolor="white", height=0.6)
        ax1.set_yticks(range(len(names_l)))
        ax1.set_yticklabels(names_l)
        for i, c in enumerate(counts_l):
            ax1.text(c + 0.2, i, str(c), va="center", fontsize=10)
    ax1.set_xlabel("Frequency")
    ax1.set_title("Most Liked Aspects")
    ax1.xaxis.set_major_locator(plt.MaxNLocator(integer=True))
    ax1.grid(axis="x", alpha=0.3)

    # Suggestion themes
    sugg = {k: v for k, v in qual["suggestions"].items() if v["count"] > 0}
    sugg_sorted = sorted(sugg.items(), key=lambda x: x[1]["count"])
    if sugg_sorted:
        names_s = [n for n, _ in sugg_sorted]
        counts_s = [d["count"] for _, d in sugg_sorted]
        ax2.barh(range(len(names_s)), counts_s, color=COLORS["warning"],
                 edgecolor="white", height=0.6)
        ax2.set_yticks(range(len(names_s)))
        ax2.set_yticklabels(names_s)
        for i, c in enumerate(counts_s):
            ax2.text(c + 0.2, i, str(c), va="center", fontsize=10)
    ax2.set_xlabel("Frequency")
    ax2.set_title("Suggested Improvements")
    ax2.xaxis.set_major_locator(plt.MaxNLocator(integer=True))
    ax2.grid(axis="x", alpha=0.3)

    fig.tight_layout()
    _save_chart(fig, "qualitative_themes")


# ---------------------------------------------------------------------------
# LaTeX Generation
# ---------------------------------------------------------------------------
def latex_escape(text):
    """Escape LaTeX special characters in text."""
    if not isinstance(text, str):
        text = str(text)
    conv = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    # Replace backslash first
    text = text.replace("\\", r"\textbackslash{}")
    for char in ["&", "%", "$", "#", "_", "{", "}", "~", "^"]:
        text = text.replace(char, conv[char])
    # Convert en-dashes
    text = text.replace("\u2013", "--")
    text = text.replace("\u2014", "---")
    return text


def generate_latex(sus, features, demo, sat, qual, df):
    parts = []

    # Preamble comment
    parts.append("% evaluation.tex -- Auto-generated by generate_evaluation.py")
    parts.append("% Requires: booktabs, graphicx, tabularx, amsmath packages")
    parts.append("% Include in main document with: \\input{evaluation/evaluation}")
    parts.append("")

    parts.append(latex_methodology(demo))
    parts.append(latex_demographics(demo))
    parts.append(latex_sus(sus, df))
    parts.append(latex_features(features))
    parts.append(latex_satisfaction(sat))
    parts.append(latex_qualitative(qual))
    parts.append(latex_summary(sus, features, sat, qual))

    content = "\n".join(parts)
    with open(LATEX_FILE, "w", encoding="utf-8") as f:
        f.write(content)


def latex_methodology(demo):
    return r"""
\section{User Evaluation}
\label{sec:evaluation}

\subsection{Evaluation Methodology}
\label{subsec:methodology}

To assess the usability, functionality, and overall user experience of Aura, a structured user evaluation was conducted. The evaluation employed a mixed-methods approach combining quantitative and qualitative data collection techniques, enabling both measurable metrics and rich descriptive feedback.

\subsubsection{Survey Design}

The evaluation survey comprised four sections:

\begin{enumerate}
    \item \textbf{System Usability Scale (SUS)} --- a standardised 10-item questionnaire developed by \cite{brooke1996sus} that provides a reliable measure of perceived usability. Each item is rated on a 5-point Likert scale ranging from ``Strongly Disagree'' to ``Strongly Agree''. The SUS has been widely adopted in HCI research due to its simplicity, reliability, and well-established benchmarks \citep{bangor2009determining}.
    \item \textbf{Feature-Specific Ratings} --- eight custom questions rating individual app features on a 5-point scale from ``Very Poor'' (1) to ``Excellent'' (5), covering habit tracking, AI coaching, reminders, analytics, gamification, visual design, navigation, and information clarity.
    \item \textbf{Overall Satisfaction} --- a single 5-point rating from ``Very Dissatisfied'' to ``Very Satisfied''.
    \item \textbf{Open-Ended Questions} --- two free-text questions: ``What did you like most about Aura?'' and ``What improvements or changes would you suggest for Aura?''
\end{enumerate}

\subsubsection{Participants}

A total of """ + str(demo["n"]) + r""" participants were recruited through convenience sampling: 10 students from Heriot-Watt University Malaysia and 10 participants from outside the university. Participation was voluntary and anonymous, with informed consent obtained at the start of the survey. Participants were asked to use the Aura application before completing the survey to ensure responses were based on firsthand experience.

\subsubsection{Data Collection}

The survey was administered electronically using Microsoft Forms. Data was collected over a single session and all responses were exported to Microsoft Excel for analysis.

\subsubsection{SUS Scoring Methodology}

The System Usability Scale (SUS) yields a composite score between 0 and 100 for each respondent \citep{brooke1996sus}. The scoring procedure is as follows:

For each of the 10 SUS items, a contribution score $x_i$ is calculated from the raw Likert response $r_i$ (where $1 \leq r_i \leq 5$):

\begin{equation}
\label{eq:sus-odd}
x_i = r_i - 1 \quad \text{for odd-numbered items (positive statements: Q1, Q3, Q5, Q7, Q9)}
\end{equation}

\begin{equation}
\label{eq:sus-even}
x_i = 5 - r_i \quad \text{for even-numbered items (negative statements: Q2, Q4, Q6, Q8, Q10)}
\end{equation}

This normalisation maps each item contribution to the range $[0, 4]$, where higher values indicate more positive responses regardless of item polarity. The final SUS score is computed as:

\begin{equation}
\label{eq:sus-score}
SUS = \left(\sum_{i=1}^{10} x_i\right) \times 2.5
\end{equation}

The multiplication factor of 2.5 scales the raw sum (range $[0, 40]$) to a percentage-like score in the range $[0, 100]$.

\subsubsection{Descriptive Statistics}

The following standard descriptive statistics were computed for all quantitative measures:

The \textbf{arithmetic mean} ($\bar{x}$) provides the central tendency:
\begin{equation}
\label{eq:mean}
\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i
\end{equation}

The \textbf{sample standard deviation} ($s$) measures the dispersion of scores:
\begin{equation}
\label{eq:std}
s = \sqrt{\frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2}
\end{equation}

where $n$ is the number of respondents. The sample standard deviation uses $n-1$ (Bessel's correction) to provide an unbiased estimate of the population variance.

The \textbf{median} ($\tilde{x}$) provides a robust measure of central tendency unaffected by outliers.
"""


def latex_demographics(demo):
    lines = []
    lines.append(r"""
\subsection{Participant Demographics}
\label{subsec:demographics}

""")

    # Age table
    lines.append(r"\begin{table}[htbp]")
    lines.append(r"\centering")
    lines.append(r"\caption{Distribution of Respondents by Age Range}")
    lines.append(r"\label{tab:demo-age}")
    lines.append(r"\begin{tabular}{lrr}")
    lines.append(r"\toprule")
    lines.append(r"\textbf{Age Range} & \textbf{Count} & \textbf{Percentage (\%)} \\")
    lines.append(r"\midrule")
    for age, count in demo["age"].items():
        if count > 0:
            age_latex = age.replace("\u2013", "--")
            pct = demo["age_pct"][age]
            lines.append(f"{age_latex} & {count} & {pct} \\\\")
    lines.append(r"\midrule")
    lines.append(f'\\textbf{{Total}} & \\textbf{{{demo["n"]}}} & \\textbf{{100.0}} \\\\')
    lines.append(r"\bottomrule")
    lines.append(r"\end{tabular}")
    lines.append(r"\end{table}")
    lines.append("")

    # Experience table
    lines.append(r"\begin{table}[htbp]")
    lines.append(r"\centering")
    lines.append(r"\caption{Distribution of Respondents by Mobile App Experience Level}")
    lines.append(r"\label{tab:demo-experience}")
    lines.append(r"\begin{tabular}{lrr}")
    lines.append(r"\toprule")
    lines.append(r"\textbf{Experience Level} & \textbf{Count} & \textbf{Percentage (\%)} \\")
    lines.append(r"\midrule")
    for exp, count in demo["experience"].items():
        if count > 0:
            lines.append(f"{exp} & {count} & {demo['experience_pct'][exp]} \\\\")
    lines.append(r"\midrule")
    lines.append(f'\\textbf{{Total}} & \\textbf{{{demo["n"]}}} & \\textbf{{100.0}} \\\\')
    lines.append(r"\bottomrule")
    lines.append(r"\end{tabular}")
    lines.append(r"\end{table}")
    lines.append("")

    # Chart references
    lines.append(r"\begin{figure}[htbp]")
    lines.append(r"\centering")
    lines.append(r"\includegraphics[width=0.65\textwidth]{evaluation/charts/demographics_age.png}")
    lines.append(r"\caption{Distribution of respondents by age range.}")
    lines.append(r"\label{fig:demo-age}")
    lines.append(r"\end{figure}")
    lines.append("")

    lines.append(r"\begin{figure}[htbp]")
    lines.append(r"\centering")
    lines.append(r"\includegraphics[width=0.65\textwidth]{evaluation/charts/demographics_experience.png}")
    lines.append(r"\caption{Distribution of respondents by mobile app experience level.}")
    lines.append(r"\label{fig:demo-experience}")
    lines.append(r"\end{figure}")
    lines.append("")

    # Narrative
    majority_age = max(demo["age"], key=demo["age"].get).replace("\u2013", "--")
    majority_age_pct = demo["age_pct"][max(demo["age"], key=demo["age"].get)]
    majority_exp = max(demo["experience"], key=demo["experience"].get)
    majority_exp_pct = demo["experience_pct"][majority_exp]

    lines.append(
        f"As shown in Table~\\ref{{tab:demo-age}} and Figure~\\ref{{fig:demo-age}}, "
        f"the largest age group was {majority_age} years, accounting for "
        f"{majority_age_pct}\\% of respondents. "
        f"Table~\\ref{{tab:demo-experience}} and Figure~\\ref{{fig:demo-experience}} "
        f"show that the majority of participants ({majority_exp_pct}\\%) described "
        f"themselves as having ``{majority_exp}'' experience with mobile applications, "
        f"indicating that the evaluation sample was representative of typical app users."
    )
    lines.append("")

    return "\n".join(lines)


def latex_sus(sus, df):
    lines = []
    lines.append(r"""
\subsection{System Usability Scale (SUS) Analysis}
\label{subsec:sus}

The SUS questionnaire was administered to all """ + str(len(sus["scores"])) + r""" participants. Table~\ref{tab:sus-questions} lists the 10 SUS items as presented to respondents.

\begin{table}[htbp]
\centering
\caption{System Usability Scale (SUS) Questions}
\label{tab:sus-questions}
\begin{tabular}{cp{12cm}}
\toprule
\textbf{Item} & \textbf{Statement} \\
\midrule""")

    for i, q in enumerate(SUS_QUESTIONS, 1):
        polarity = "(+)" if i % 2 == 1 else "(\u2013)"
        polarity_latex = "(+)" if i % 2 == 1 else "(--)"
        lines.append(f"Q{i} {polarity_latex} & {latex_escape(q)} \\\\")

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    # Worked example
    r1_raw = [df.iloc[0][c] for c in df.attrs["sus_cols"]]
    lines.append(r"""\subsubsection{Worked Example}

To illustrate the SUS scoring procedure, consider Respondent~1 whose raw Likert responses were:""")

    lines.append("")
    lines.append(r"\begin{center}")
    lines.append(r"\begin{tabular}{cccccccccc}")
    lines.append(r"\toprule")
    lines.append(" & ".join([f"\\textbf{{Q{i}}}" for i in range(1, 11)]) + r" \\")
    lines.append(r"\midrule")
    lines.append(" & ".join([str(int(v)) for v in r1_raw]) + r" \\")
    lines.append(r"\bottomrule")
    lines.append(r"\end{tabular}")
    lines.append(r"\end{center}")
    lines.append("")

    lines.append(r"Applying Equations~\ref{eq:sus-odd} and~\ref{eq:sus-even}:")
    lines.append("")
    lines.append(r"\begin{align*}")

    adjusted = []
    for i, val in enumerate(r1_raw):
        val = int(val)
        q_num = i + 1
        if q_num % 2 == 1:
            adj = val - 1
            lines.append(f"x_{{{q_num}}} &= r_{{{q_num}}} - 1 = {val} - 1 = {adj} \\\\")
        else:
            adj = 5 - val
            lines.append(f"x_{{{q_num}}} &= 5 - r_{{{q_num}}} = 5 - {val} = {adj} \\\\")
        adjusted.append(adj)

    lines.append(r"\end{align*}")
    lines.append("")

    total = sum(adjusted)
    sus_score = total * 2.5
    lines.append(r"Applying Equation~\ref{eq:sus-score}:")
    lines.append("")
    lines.append(r"\begin{equation*}")
    adj_str = " + ".join(str(a) for a in adjusted)
    lines.append(f"SUS = ({adj_str}) \\times 2.5 = {total} \\times 2.5 = {sus_score:.1f}")
    lines.append(r"\end{equation*}")
    lines.append("")

    # Individual scores table
    lines.append(r"""\subsubsection{Individual SUS Scores}

Table~\ref{tab:sus-individual} presents the SUS score and grade for each respondent.

\begin{table}[htbp]
\centering
\caption{Individual SUS Scores and Grades}
\label{tab:sus-individual}
\begin{tabular}{crc}
\toprule
\textbf{Respondent} & \textbf{SUS Score} & \textbf{Grade} \\
\midrule""")

    for i, (score, grade) in enumerate(zip(sus["scores"], sus["individual_grades"])):
        lines.append(f"R{i+1} & {score:.1f} & {grade} \\\\")

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    # Summary statistics table
    lines.append(r"""\subsubsection{Descriptive Statistics}

Table~\ref{tab:sus-stats} summarises the descriptive statistics for the SUS scores.

\begin{table}[htbp]
\centering
\caption{SUS Score Descriptive Statistics}
\label{tab:sus-stats}
\begin{tabular}{lr}
\toprule
\textbf{Metric} & \textbf{Value} \\
\midrule""")

    lines.append(f'Mean ($\\bar{{x}}$) & {sus["mean"]:.2f} \\\\')
    lines.append(f'Standard Deviation ($s$) & {sus["std"]:.2f} \\\\')
    lines.append(f'Median ($\\tilde{{x}}$) & {sus["median"]:.1f} \\\\')
    lines.append(f'Minimum & {sus["min"]:.1f} \\\\')
    lines.append(f'Maximum & {sus["max"]:.1f} \\\\')
    lines.append(r"\midrule")
    lines.append(f'Adjective Rating & {sus["adjective"]} \\\\')
    lines.append(f'Grade & {sus["grade"]} \\\\')
    lines.append(f'Acceptability & {sus["acceptability"]} \\\\')

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    # SUS by experience level
    lines.append(r"""\subsubsection{SUS Scores by Experience Level}

Table~\ref{tab:sus-experience} presents the mean SUS scores cross-tabulated by participants' self-reported mobile app experience level.

\begin{table}[htbp]
\centering
\caption{Mean SUS Scores by Experience Level}
\label{tab:sus-experience}
\begin{tabular}{lrrr}
\toprule
\textbf{Experience Level} & \textbf{$n$} & \textbf{Mean} & \textbf{SD} \\
\midrule""")

    for exp in ["Beginner", "Intermediate", "Advanced"]:
        if exp in sus["by_experience"]:
            data = sus["by_experience"][exp]
            lines.append(f'{exp} & {data["n"]} & {data["mean"]:.2f} & {data["std"]:.2f} \\\\')

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    # Charts
    lines.append(r"""\begin{figure}[htbp]
\centering
\includegraphics[width=0.85\textwidth]{evaluation/charts/sus_distribution.png}
\caption{Distribution of SUS scores across all respondents with acceptability range shading.}
\label{fig:sus-distribution}
\end{figure}

\begin{figure}[htbp]
\centering
\includegraphics[width=0.85\textwidth]{evaluation/charts/sus_individual.png}
\caption{Individual SUS scores by respondent, colour-coded by letter grade.}
\label{fig:sus-individual}
\end{figure}

\begin{figure}[htbp]
\centering
\includegraphics[width=0.95\textwidth]{evaluation/charts/sus_adjective_scale.png}
\caption{SUS adjective rating scale showing Aura's position relative to established benchmarks \citep{bangor2009determining}.}
\label{fig:sus-adjective}
\end{figure}
""")

    # Narrative interpretation
    lines.append(
        f"The evaluation yielded a mean SUS score of $M = {sus['mean']:.2f}$ "
        f"($SD = {sus['std']:.2f}$, $Mdn = {sus['median']:.1f}$), "
        f"ranging from a minimum of {sus['min']:.1f} to a maximum of {sus['max']:.1f}. "
        f"According to the adjective rating scale proposed by \\cite{{bangor2009determining}}, "
        f"this places Aura in the ``{sus['adjective']}'' category with a letter grade of "
        f"``{sus['grade']}'' and falls within the ``{sus['acceptability']}'' range "
        f"(Figure~\\ref{{fig:sus-adjective}}). "
        f"The industry average SUS score is approximately 68 \\citep{{sauro2016quantifying}}; "
        f"Aura's score of {sus['mean']:.2f} exceeds this benchmark, "
        f"indicating above-average perceived usability."
    )
    lines.append("")
    lines.append(
        "As shown in Figure~\\ref{fig:sus-distribution}, the distribution of individual "
        "scores is concentrated in the upper range, with the majority of respondents "
        "scoring above the 68-point benchmark. Figure~\\ref{fig:sus-individual} reveals "
        "that the scores are relatively consistent across respondents, suggesting a "
        "broadly positive usability experience."
    )
    lines.append("")

    return "\n".join(lines)


def latex_features(features):
    lines = []
    lines.append(r"""
\subsection{Feature Rating Analysis}
\label{subsec:features}

Respondents rated eight specific features of Aura on a 5-point scale, where 1 represents ``Very Poor'' and 5 represents ``Excellent''. Table~\ref{tab:feature-stats} summarises the descriptive statistics for each feature, ranked by mean score.

\begin{table}[htbp]
\centering
\caption{Feature Rating Summary Statistics (Ranked by Mean)}
\label{tab:feature-stats}
\begin{tabular}{rlrrr}
\toprule
\textbf{Rank} & \textbf{Feature} & \textbf{Mean} & \textbf{Median} & \textbf{SD} \\
\midrule""")

    ranked = sorted(features.items(), key=lambda x: x[1]["rank"])
    for name, data in ranked:
        name_latex = name.replace("&", r"\&")
        lines.append(
            f'{data["rank"]} & {name_latex} & {data["mean"]:.2f} & '
            f'{data["median"]:.1f} & {data["std"]:.2f} \\\\'
        )

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    # Distribution table
    lines.append(r"""\begin{table}[htbp]
\centering
\caption{Feature Rating Distribution (Number of Respondents per Rating)}
\label{tab:feature-distribution}
\begin{tabular}{lrrrrr}
\toprule
\textbf{Feature} & \textbf{1} & \textbf{2} & \textbf{3} & \textbf{4} & \textbf{5} \\
\midrule""")

    for name, data in ranked:
        name_latex = name.replace("&", r"\&")
        d = data["distribution"]
        lines.append(
            f'{name_latex} & {d.get(1,0)} & {d.get(2,0)} & {d.get(3,0)} & '
            f'{d.get(4,0)} & {d.get(5,0)} \\\\'
        )

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    # Charts
    lines.append(r"""\begin{figure}[htbp]
\centering
\includegraphics[width=0.85\textwidth]{evaluation/charts/feature_comparison.png}
\caption{Feature ratings comparison ranked by mean score with standard deviation error bars.}
\label{fig:feature-comparison}
\end{figure}

\begin{figure}[htbp]
\centering
\includegraphics[width=0.95\textwidth]{evaluation/charts/feature_distribution.png}
\caption{Distribution of ratings across all features.}
\label{fig:feature-distribution}
\end{figure}
""")

    # Narrative
    top = ranked[0]
    bottom = ranked[-1]
    overall_mean = np.mean([d["mean"] for _, d in ranked])
    top_name = top[0].replace("&", r"\&")
    bottom_name = bottom[0].replace("&", r"\&")

    lines.append(
        f"As presented in Table~\\ref{{tab:feature-stats}} and "
        f"Figure~\\ref{{fig:feature-comparison}}, the overall mean across all features "
        f"was {overall_mean:.2f} out of 5. The highest-rated feature was "
        f"``{top_name}'' ($M = {top[1]['mean']:.2f}$, $SD = {top[1]['std']:.2f}$), "
        f"whilst the lowest-rated was "
        f"``{bottom_name}'' ($M = {bottom[1]['mean']:.2f}$, $SD = {bottom[1]['std']:.2f}$). "
        f"Figure~\\ref{{fig:feature-distribution}} illustrates the distribution of ratings, "
        f"showing that the majority of responses fell in the ``Good'' (4) and "
        f"``Excellent'' (5) categories across all features."
    )
    lines.append("")

    return "\n".join(lines)


def latex_satisfaction(sat):
    lines = []
    lines.append(r"""
\subsection{Overall Satisfaction}
\label{subsec:satisfaction}

Respondents were asked to rate their overall satisfaction with Aura on a 5-point scale. Table~\ref{tab:satisfaction} presents the distribution of responses.

\begin{table}[htbp]
\centering
\caption{Overall Satisfaction Distribution}
\label{tab:satisfaction}
\begin{tabular}{lrr}
\toprule
\textbf{Rating} & \textbf{Count} & \textbf{Percentage (\%)} \\
\midrule""")

    for r in range(5, 0, -1):
        label = SATISFACTION_LABELS[r]
        count = sat["distribution"].get(r, 0)
        pct = sat["distribution_pct"].get(r, 0)
        lines.append(f"{r} -- {label} & {count} & {pct} \\\\")

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    lines.append(r"""\begin{figure}[htbp]
\centering
\includegraphics[width=0.75\textwidth]{evaluation/charts/satisfaction_distribution.png}
\caption{Distribution of overall satisfaction ratings.}
\label{fig:satisfaction}
\end{figure}
""")

    # Count satisfied + very satisfied
    sat_count = sat["distribution"].get(4, 0) + sat["distribution"].get(5, 0)
    total = sum(sat["distribution"].values())
    sat_pct = sat_count / total * 100

    lines.append(
        f"The mean overall satisfaction score was $M = {sat['mean']:.2f}$ "
        f"($SD = {sat['std']:.2f}$, $Mdn = {sat['median']:.1f}$) on a 5-point scale. "
        f"As shown in Table~\\ref{{tab:satisfaction}} and Figure~\\ref{{fig:satisfaction}}, "
        f"{sat_pct:.1f}\\% of respondents rated their experience as either ``Satisfied'' "
        f"or ``Very Satisfied'' ($n = {sat_count}$), indicating a strong positive reception "
        f"of the application overall."
    )
    lines.append("")

    return "\n".join(lines)


def latex_qualitative(qual):
    lines = []
    lines.append(r"""
\subsection{Qualitative Feedback Analysis}
\label{subsec:qualitative}

Two open-ended questions were included in the survey to capture richer qualitative feedback. Responses were analysed using thematic analysis, whereby recurring topics were identified and categorised into themes through keyword-based classification.

\subsubsection{Most Liked Aspects}

Table~\ref{tab:liked-themes} presents the themes identified from responses to ``What did you like most about Aura?'' along with their frequency and representative quotes.

\begin{table}[htbp]
\centering
\caption{Thematic Analysis of Most Liked Aspects}
\label{tab:liked-themes}
\begin{tabular}{lrp{8cm}}
\toprule
\textbf{Theme} & \textbf{Freq.} & \textbf{Representative Quote} \\
\midrule""")

    for theme, data in qual["liked"].items():
        if data["count"] > 0:
            quote = data["quotes"][0] if data["quotes"] else ""
            # Truncate long quotes
            if len(quote) > 70:
                quote = quote[:67] + "..."
            quote = latex_escape(quote)
            theme_escaped = latex_escape(theme)
            lines.append(f"{theme_escaped} & {data['count']} & \\textit{{{quote}}} \\\\")

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    # Suggestions table
    lines.append(r"""\subsubsection{Suggested Improvements}

Table~\ref{tab:suggestion-themes} presents the themes identified from responses to ``What improvements or changes would you suggest for Aura?''

\begin{table}[htbp]
\centering
\caption{Thematic Analysis of Suggested Improvements}
\label{tab:suggestion-themes}
\begin{tabular}{lrp{8cm}}
\toprule
\textbf{Theme} & \textbf{Freq.} & \textbf{Representative Quote} \\
\midrule""")

    for theme, data in qual["suggestions"].items():
        if data["count"] > 0:
            quote = data["quotes"][0] if data["quotes"] else ""
            if len(quote) > 70:
                quote = quote[:67] + "..."
            quote = latex_escape(quote)
            theme_escaped = latex_escape(theme)
            lines.append(f"{theme_escaped} & {data['count']} & \\textit{{{quote}}} \\\\")

    lines.append(r"""\bottomrule
\end{tabular}
\end{table}
""")

    lines.append(r"""\begin{figure}[htbp]
\centering
\includegraphics[width=0.95\textwidth]{evaluation/charts/qualitative_themes.png}
\caption{Frequency of themes identified in qualitative feedback.}
\label{fig:qualitative-themes}
\end{figure}
""")

    # Narrative
    top_liked = max(qual["liked"].items(), key=lambda x: x[1]["count"])
    top_suggestion = max(qual["suggestions"].items(), key=lambda x: x[1]["count"])

    lines.append(
        f"The qualitative analysis revealed that the most frequently praised aspect "
        f"of Aura was ``{latex_escape(top_liked[0])}'' (mentioned by {top_liked[1]['count']} "
        f"respondents), reflecting the value users placed on the application's "
        f"distinctive features. On the improvement side, "
        f"``{latex_escape(top_suggestion[0])}'' was the most common theme "
        f"({top_suggestion[1]['count']} respondents), suggesting clear directions for "
        f"future development."
    )
    lines.append("")
    lines.append(
        "Notably, the qualitative feedback was overwhelmingly constructive rather than "
        "critical --- respondents suggested additions and enhancements rather than "
        "reporting usability problems or defects. This aligns with the strong SUS "
        "scores and high satisfaction ratings reported in the preceding sections."
    )
    lines.append("")

    return "\n".join(lines)


def latex_summary(sus, features, sat, qual):
    ranked = sorted(features.items(), key=lambda x: x[1]["rank"])
    top_feature = ranked[0][0].replace("&", r"\&")
    sat_good = sat["distribution"].get(4, 0) + sat["distribution"].get(5, 0)
    total = sum(sat["distribution"].values())
    sat_pct = sat_good / total * 100

    return f"""
\\subsection{{Summary of Findings}}
\\label{{subsec:eval-summary}}

The user evaluation of Aura yielded encouraging results across all dimensions assessed. The System Usability Scale analysis produced a mean score of $M = {sus['mean']:.2f}$ ($SD = {sus['std']:.2f}$), placing the application in the ``{sus['adjective']}'' category with a grade of ``{sus['grade']}'' and within the ``{sus['acceptability']}'' acceptability range. This score exceeds the widely cited industry average of 68 \\citep{{sauro2016quantifying}}, indicating that users found Aura to be usable and accessible.

Feature-specific ratings were consistently positive, with ``{top_feature}'' receiving the highest mean score among the eight features evaluated. The overall satisfaction measure further reinforced these findings, with {sat_pct:.1f}\\% of respondents reporting they were ``Satisfied'' or ``Very Satisfied'' ($M = {sat['mean']:.2f}$).

Qualitative feedback highlighted the AI coaching features, visual design, and gamification elements as key strengths, whilst user suggestions centred on feature additions (such as home screen widgets and habit grouping) and minor UI refinements rather than fundamental usability issues. Limitations of the evaluation are discussed in Section~\\ref{{sec:disc_limitations}}.
"""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    os.makedirs(CHARTS_DIR, exist_ok=True)

    print("Loading survey data...")
    df = load_data(EXCEL_FILE)
    print(f"  Loaded {len(df)} responses.")

    print("Computing SUS scores...")
    sus = compute_sus_scores(df)
    print(f"  Mean SUS: {sus['mean']:.2f} ({sus['adjective']}, Grade {sus['grade']})")

    print("Analysing feature ratings...")
    features = analyze_feature_ratings(df)

    print("Analysing demographics...")
    demo = analyze_demographics(df)

    print("Analysing satisfaction...")
    sat = analyze_satisfaction(df)

    print("Analysing qualitative feedback...")
    qual = analyze_qualitative(df)

    print("Generating charts...")
    chart_sus_distribution(sus)
    chart_sus_individual(sus)
    chart_sus_adjective(sus)
    chart_feature_comparison(features)
    chart_feature_distribution(features)
    chart_demographics_age(demo)
    chart_demographics_experience(demo)
    chart_satisfaction(sat)
    chart_qualitative_themes(qual)
    print(f"  Saved 9 charts to {CHARTS_DIR}/")

    print("Generating LaTeX...")
    generate_latex(sus, features, demo, sat, qual, df)
    print(f"  Saved to {LATEX_FILE}")

    print("\nDone! Summary:")
    print(f"  SUS Score:     {sus['mean']:.2f} ({sus['adjective']}, Grade {sus['grade']}, {sus['acceptability']})")
    print(f"  Satisfaction:  {sat['mean']:.2f}/5.00")
    print(f"  Top Feature:   {sorted(features.items(), key=lambda x: x[1]['rank'])[0][0]}")
    print(f"  Output:        {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
