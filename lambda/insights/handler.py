import json
import os
from datetime import datetime, timedelta
from typing import Any

from shared.bedrock_client import BedrockClient


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }


INSIGHTS_SYSTEM = """\
You are **Plutus Bestie** — a Gen-Z personal finance coach who's genuinely hyped about \
helping people save money and build wealth. You're like that one friend who studied finance \
but explains it in a way that doesn't make your brain hurt. You use light humor, relatable \
analogies, and actual encouragement — no boring corporate speak.

## RESPONSE FORMAT
- Return **ONLY** a single, valid JSON object. No markdown fences, no prose outside the JSON.
- Every `title`, `body`, and `summary` field MUST be written in the **locale language** \
(locale=vi → Vietnamese; locale=en → English).

## WRITING RULES
1. **Tone**: Warm, friendly, a little cheeky, always encouraging. Think "financially savvy \
bestie texting you". For English: light Gen-Z phrasing is welcome (e.g., "no cap", "lowkey", \
"that's giving broke energy"). For Vietnamese: casual "bạn" form with relatable humor.
2. **Explain the jargon**: The first time you use a financial term (e.g., "savings rate", \
"cash flow", "expense ratio"), explain it in plain language in parentheses — \
e.g., "your savings rate (that's the % of your income you actually keep, not spend) is 18%".
3. **Precision**: Quote exact figures from the data. Use the user's `currency` symbol. \
Format large numbers with thousand separators (e.g., "1,250,000 VND", "$1,250"). \
For percentage changes, use signed format: "+12.5%", "−8.3%".
4. **Depth**: Bodies must be 4–6 sentences. Include: what the number is, why it matters, \
how it compares to a benchmark or prior period, a relatable analogy, and a concrete next step. \
Summaries must be 2–4 sentences.
5. **Actionable**: Every insight body MUST include a specific, doable next step — not \
"spend less on food" but "try meal prepping on Sundays — users who do this typically cut \
food costs by 20–30%".
6. **Severity mapping**: \
"warning" = overspending, budget breach, negative cash-flow trend. \
"info" = neutral observation, seasonal pattern, benchmark comparison. \
"positive" = savings goal met, spending decreased, surplus detected.
7. **Titles**: ≤ 60 characters. Make them punchy and fun, not bland.
8. **Vietnam context**: For Vietnamese locale, reference local context where relevant \
(Tết spending surge, vàng SJC gold prices, tiết kiệm bank accounts at local banks like \
Vietcombank/MB/Techcombank, chứng chỉ quỹ mutual funds).
9. **No financial advice disclaimer needed** — this is a personal finance tool, not a \
regulated advisory service."""


# ── Numerical helpers ─────────────────────────────────────────────────────────

def _safe_avg(values: list) -> float:
    floats = [float(v) for v in values if v is not None]
    return sum(floats) / len(floats) if floats else 0.0


def _compute_health_score(avg_income: float, avg_expense: float, daily_spending: list) -> dict:
    """Compute a 0–100 financial health score from key metrics."""
    savings_rate = max(0.0, (avg_income - avg_expense) / avg_income) if avg_income > 0 else 0.0
    savings_score = min(100.0, savings_rate * 200.0)  # 50% savings → 100

    consistency_score = 70.0
    if len(daily_spending) >= 7:
        mean = sum(daily_spending) / len(daily_spending)
        if mean > 0:
            variance = sum((x - mean) ** 2 for x in daily_spending) / len(daily_spending)
            cv = (variance ** 0.5) / mean
            consistency_score = max(0.0, min(100.0, 100.0 - cv * 40.0))

    ratio = avg_income / avg_expense if avg_expense > 0 else 2.0
    ratio_score = min(100.0, max(0.0, (ratio - 0.8) * 80.0))

    total = savings_score * 0.4 + consistency_score * 0.3 + ratio_score * 0.3
    return {
        "score": int(round(total)),
        "previousScore": None,
        "components": {
            "savings": {"value": round(savings_rate, 3), "score": int(round(savings_score))},
            "consistency": {"value": round(consistency_score / 100, 3), "score": int(round(consistency_score))},
            "balance": {"value": round(ratio, 2), "score": int(round(ratio_score))},
        },
    }


def _compute_daily_projections(
    avg_income: float, avg_expense: float, current_date_str: str
) -> tuple[list, dict]:
    """Build 30-day daily cash-flow projections in 3 scenarios."""
    try:
        start = datetime.strptime(current_date_str, "%Y-%m-%d").date()
    except ValueError:
        start = datetime.now().date()

    daily_income = avg_income / 30
    daily_exp_likely = avg_expense / 30
    daily_exp_opt = daily_exp_likely * 0.85   # −15% spending
    daily_exp_pess = daily_exp_likely * 1.20  # +20% spending

    projections = []
    for i in range(30):
        d = start + timedelta(days=i + 1)
        projections.append({
            "date": d.isoformat(),
            "optimistic": round(daily_income - daily_exp_opt, 0),
            "likely": round(daily_income - daily_exp_likely, 0),
            "pessimistic": round(daily_income - daily_exp_pess, 0),
        })

    projected_balance = {
        "optimistic": round(sum(p["optimistic"] for p in projections), 0),
        "likely": round(sum(p["likely"] for p in projections), 0),
        "pessimistic": round(sum(p["pessimistic"] for p in projections), 0),
    }
    return projections, projected_balance


# ── Prompt builder ────────────────────────────────────────────────────────────

def _fmt(amount: float, currency: str) -> str:
    """Format an amount with thousand separators and currency."""
    if currency == "VND":
        return f"{amount:,.0f} {currency}"
    return f"{currency} {amount:,.2f}"


def _build_prompt(
    locale: str,
    requested_types: list,
    data: dict,
    health_score: dict,
    projected_balance: dict,
    avg_income: float,
    avg_expense: float,
    savings_rate: float,
) -> str:
    currency = data.get("currency", "VND")
    current_date = data.get("currentDate", datetime.now().date().isoformat())
    period_months = int(data.get("periodMonths", 3))
    period_label = f"{period_months}-month"
    categories = sorted(
        data.get("categories", []),
        key=lambda c: (c.get("amounts") or [0])[0],
        reverse=True,
    )[:10]
    top_merchants = data.get("topMerchants", [])[:10]

    lang = "Vietnamese" if locale == "vi" else "English"
    net_monthly = avg_income - avg_expense

    lines = [
        f"## USER FINANCIAL SNAPSHOT (as of {current_date}, {period_label} analysis period)",
        f"- **Locale**: {locale} — write ALL text fields in **{lang}**.",
        f"- **Currency**: {currency}.",
        f"- **Monthly gross income**: {_fmt(avg_income, currency)} ({period_label} average).",
        f"- **Monthly total expenses**: {_fmt(avg_expense, currency)} ({period_label} average).",
        f"- **Net monthly cash flow**: {_fmt(net_monthly, currency)} "
        + ("(surplus — nice!)." if net_monthly >= 0 else "(deficit — let's fix this)."),
        f"- **Savings rate**: {savings_rate:.1%} of gross income "
        f"({'above' if savings_rate >= 0.2 else 'below'} the recommended 20% benchmark).",
        f"- **Analysis period**: {period_months} month(s).",
    ]

    if categories:
        lines.append(f"\n### EXPENSE BREAKDOWN BY CATEGORY ({period_label} totals)")
        for i, c in enumerate(categories, 1):
            amt = (c.get("amounts") or [0])[0]
            cnt = (c.get("txCount") or [0])[0]
            pct = (amt / avg_expense * 100) if avg_expense > 0 else 0
            lines.append(
                f"  {i}. **{c.get('name', 'Other')}**: "
                f"{_fmt(amt, currency)} ({pct:.1f}% of expenses, {cnt} transactions)."
            )

    if top_merchants:
        lines.append("\n### TOP MERCHANTS BY SPEND")
        for m in top_merchants:
            lines.append(
                f"  - **{m.get('name', '')}** [{m.get('category', '')}]: "
                f"{_fmt(m.get('total', 0), currency)} across {m.get('count', 0)} transactions."
            )

    if health_score:
        comp = health_score["components"]
        lines.append(f"\n### FINANCIAL HEALTH SCORE: **{health_score['score']}/100**")
        lines.append("  (Score guide: 0–49 = needs work, 50–74 = decent, 75–100 = slay)")
        lines.append(
            f"  - Savings sub-score: {comp['savings']['score']}/100 "
            f"(rate: {comp['savings']['value']:.1%})."
        )
        lines.append(
            f"  - Consistency sub-score: {comp['consistency']['score']}/100 "
            f"(spending volatility: {'low — very stable' if comp['consistency']['score'] >= 70 else 'high — quite erratic'})."
        )
        lines.append(
            f"  - Income-to-expense ratio sub-score: {comp['balance']['score']}/100 "
            f"(ratio: {comp['balance']['value']:.2f}x — ideally you want >1.2x)."
        )

    if projected_balance:
        lines.append("\n### 30-DAY PROJECTED NET CASH FLOW")
        lines.append(f"  - **Best case** (if you cut spending 15%): {_fmt(projected_balance['optimistic'], currency)}.")
        lines.append(f"  - **Most likely** (baseline spending continues): {_fmt(projected_balance['likely'], currency)}.")
        lines.append(f"  - **Worst case** (if spending jumps 20%): {_fmt(projected_balance['pessimistic'], currency)}.")

    want_spending = "spending" in requested_types
    want_forecast = "forecast" in requested_types
    want_alerts = "alerts" in requested_types
    want_coaching = "coaching" in requested_types

    lines.append("\n---")
    lines.append("## YOUR TASK")
    lines.append(
        "Produce a JSON object matching the **exact schema** below. "
        "Replace every `\"<FILL>\"` placeholder with real content derived from the data above. "
        "Write in the Gen-Z bestie tone described in the system prompt. "
        "Explain financial terms in parentheses on first use within each text field."
    )

    schema: dict = {"generatedAt": f"{current_date}T00:00:00.000Z"}

    if want_spending and health_score:
        lines.append(
            "\n**healthScore.summary**: Write 2–3 sentences interpreting the score with Gen-Z energy. "
            "Explain what the score means (e.g., 'think of it like a credit score but for your whole financial vibe'). "
            "Reference the weakest sub-score and give one fun, specific improvement tip."
        )
        schema["healthScore"] = {
            **health_score,
            "summary": "<FILL: 2-3 sentence score interpretation with financial term explanation>",
        }
    else:
        schema["healthScore"] = None

    if want_spending:
        lines.append(
            "\n**spending[]**: Generate exactly **5** spending insights (4–6 sentences each):"
        )
        lines.append(
            "  1. `si_1` — **Biggest money drain**: Your top expense category. Cite the exact amount "
            "and % of total expenses. Explain why this category matters, compare to a realistic benchmark, "
            "add a relatable analogy (e.g., 'that's basically 3 months of Netflix per day'), "
            "and give one specific action. severity=`warning` if >35% of expenses, else `info`."
        )
        lines.append(
            "  2. `si_2` — **Sneaky spending pattern**: A merchant concentration, recurring charge, "
            "or unusual spike that the user might not have noticed. Explain why this is worth watching. "
            "severity=`warning` or `info`."
        )
        lines.append(
            "  3. `si_3` — **Green flag moment**: A category where spending is well-controlled or "
            "improving. Celebrate it! Reference the specific numbers and explain why this habit compounds "
            "positively over time. severity=`positive`."
        )
        lines.append(
            "  4. `si_4` — **Savings rate check**: Analyse the savings rate (% of income kept, not spent). "
            "Compare to the 20% rule and 50/30/20 budgeting framework "
            "(explain: '50% needs, 30% wants, 20% savings'). "
            "If below 10%, call it out with empathy. severity=`warning` if <10%, `info` if 10–20%, `positive` if >20%."
        )
        lines.append(
            "  5. `si_5` — **Income-to-expense ratio**: Explain the income-to-expense ratio "
            "(income divided by expenses — you want this above 1.0 ideally above 1.2). "
            "State the current ratio. Suggest one concrete lever to improve it. "
            "severity=`warning` if ratio<1.0, `info` if 1.0–1.2, `positive` if >1.2."
        )
        schema["spending"] = [
            {
                "id": "si_1",
                "title": "<FILL: ≤60 chars, punchy>",
                "body": "<FILL: 4–6 sentences with exact figures, analogy, next step>",
                "category": "<FILL: top category name>",
                "metric": {
                    "label": "<FILL: e.g. +18.2% MoM>",
                    "direction": "<FILL: up|down|flat>",
                    "severity": "<FILL: warning|info|positive>",
                },
            },
            {
                "id": "si_2",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences>",
                "category": None,
                "metric": None,
            },
            {
                "id": "si_3",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences with celebration energy>",
                "category": None,
                "metric": None,
            },
            {
                "id": "si_4",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences explaining savings rate with 50/30/20 reference>",
                "category": None,
                "metric": {
                    "label": "<FILL: savings rate %>",
                    "direction": "<FILL: up|down|flat>",
                    "severity": "<FILL: warning|info|positive>",
                },
            },
            {
                "id": "si_5",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences explaining income-to-expense ratio>",
                "category": None,
                "metric": {
                    "label": "<FILL: ratio value>",
                    "direction": "<FILL: up|down|flat>",
                    "severity": "<FILL: warning|info|positive>",
                },
            },
        ]
    else:
        schema["spending"] = []

    if want_forecast:
        lines.append(
            "\n**forecast.summary**: Write 2–4 sentences interpreting the 3-scenario projection. "
            "Explain what 'cash flow forecast' means in plain language first "
            "('basically a prediction of how much money you'll have left at the end of the month'). "
            "State the likely outcome in currency terms. "
            "Flag risk if pessimistic is negative with a practical mitigation tip."
        )
        schema["forecast"] = {
            "projectedBalance": projected_balance,
            "dailyProjection": [],
            "summary": "<FILL: 2–4 sentence cash-flow outlook with term explanation>",
        }
    else:
        schema["forecast"] = None

    if want_alerts:
        lines.extend([
            "\n**alerts[]**: Generate 2–4 smart alerts based on the data.",
            "  - At least 1 **warning** if: savings rate <10%, any category >40% expenses, or net flow negative.",
            "  - At least 1 **positive** if: savings rate ≥20%, expenses trending down, or healthy surplus.",
            "  - Alert bodies: 2–3 sentences. Explain the metric that triggered it in plain language.",
            "  - severity must be one of: `warning`, `info`, `positive`.",
        ])
        alerts_schema = [
            {
                "id": "alert_1",
                "title": "<FILL>",
                "body": "<FILL: 2–3 sentences citing triggering metric with plain-language explanation>",
                "severity": "<FILL: warning|info|positive>",
                "isRead": False,
            },
            {
                "id": "alert_2",
                "title": "<FILL>",
                "body": "<FILL: 2–3 sentences>",
                "severity": "<FILL: warning|info|positive>",
                "isRead": False,
            },
        ]
        if savings_rate >= 0.15:
            alerts_schema.append({
                "id": "alert_3",
                "title": "<FILL: positive reinforcement>",
                "body": "<FILL: cite savings rate with celebration>",
                "severity": "positive",
                "isRead": False,
            })
        schema["alerts"] = alerts_schema
    else:
        schema["alerts"] = []

    if want_coaching:
        lines.append(
            "\n**coaching[]**: Generate exactly **5** personalized coaching tips (bodies: 4–6 sentences each):"
        )
        lines.append(
            "  1. `tip_1` (difficulty=`easy`): A **today-win** — something the user can do right now. "
            "Explain why this small action has outsized impact. No savingsEstimate needed."
        )
        lines.append(
            "  2. `tip_2` (difficulty=`easy`): Another **quick-win** focused on reducing a specific "
            "identified spending category. Include a fun analogy."
        )
        lines.append(
            "  3. `tip_3` (difficulty=`medium`): A **savings optimization** with a concrete "
            f"`savingsEstimate` in {currency} per month. "
            "Base the estimate on actual spending data. Explain the math."
        )
        lines.append(
            "  4. `tip_4` (difficulty=`medium`): An **income-boosting or cost-cutting** strategy "
            f"with another `savingsEstimate` in {currency} per month."
        )
        lines.append(
            "  5. `tip_5` (difficulty=`hard`): A **long-term wealth move** "
            "(e.g., emergency fund target explained, investment account, debt payoff). "
            "Explain the compound effect over 1–5 years with rough numbers."
        )
        if locale == "vi":
            lines.append(
                "  For Vietnamese locale: Reference local financial products where relevant "
                "(tiết kiệm ngân hàng lãi suất ~5–7%/năm, vàng SJC, chứng chỉ quỹ như VFMVF1). "
                "Mention specific local banks (Vietcombank, MB Bank, Techcombank) by name."
            )
        schema["coaching"] = [
            {
                "id": "tip_1",
                "title": "<FILL: ≤60 chars, energetic>",
                "body": "<FILL: 4–6 sentences with why this matters>",
                "savingsEstimate": None,
                "difficulty": "easy",
                "isSaved": False,
            },
            {
                "id": "tip_2",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences with analogy>",
                "savingsEstimate": None,
                "difficulty": "easy",
                "isSaved": False,
            },
            {
                "id": "tip_3",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences with savings math explained>",
                "savingsEstimate": "<FILL: number>",
                "difficulty": "medium",
                "isSaved": False,
            },
            {
                "id": "tip_4",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences>",
                "savingsEstimate": "<FILL: number>",
                "difficulty": "medium",
                "isSaved": False,
            },
            {
                "id": "tip_5",
                "title": "<FILL>",
                "body": "<FILL: 4–6 sentences with compound effect numbers>",
                "savingsEstimate": None,
                "difficulty": "hard",
                "isSaved": False,
            },
        ]
    else:
        schema["coaching"] = []

    lines.append("\n---")
    lines.append("## OUTPUT SCHEMA")
    lines.append(
        "Replace every `\"<FILL...>\"` with real content. "
        "Do NOT add, remove, or rename any keys. Return ONLY this JSON:"
    )
    lines.append(json.dumps(schema, ensure_ascii=False, indent=2))

    return "\n".join(lines)


# ── Handler ───────────────────────────────────────────────────────────────────

def handler(event: dict, context: Any) -> dict:
    """Lambda handler for POST /insights."""
    try:
        raw = event.get("body") or ""
        if isinstance(raw, str):
            payload = json.loads(raw) if raw else {}
        elif isinstance(raw, dict):
            payload = raw
        else:
            payload = {}
    except json.JSONDecodeError as exc:
        return _response(400, {"error": f"Invalid JSON: {exc}"})

    locale: str = payload.get("locale", "en")
    requested_types: list = payload.get(
        "requestedTypes", ["spending", "forecast", "alerts", "coaching"]
    )
    data: dict = payload.get("data", {})

    avg_income = _safe_avg(data.get("monthlyIncome", [0]))
    avg_expense = _safe_avg(data.get("monthlyExpense", [0]))
    daily_spending = [float(x) for x in data.get("dailySpending", []) if x is not None]
    savings_rate = max(0.0, (avg_income - avg_expense) / avg_income) if avg_income > 0 else 0.0
    current_date = data.get("currentDate", datetime.now().date().isoformat())

    health_score = _compute_health_score(avg_income, avg_expense, daily_spending)
    daily_projections, projected_balance = _compute_daily_projections(
        avg_income, avg_expense, current_date
    )

    try:
        client = BedrockClient(
            model_id=os.environ.get("BEDROCK_MODEL_ID", BedrockClient.DEFAULT_MODEL_ID),
            region=os.environ.get("AWS_REGION", "ap-southeast-1"),
            max_tokens=4096,
        )
        prompt = _build_prompt(
            locale=locale,
            requested_types=requested_types,
            data=data,
            health_score=health_score,
            projected_balance=projected_balance,
            avg_income=avg_income,
            avg_expense=avg_expense,
            savings_rate=savings_rate,
        )
        result = client.invoke(system_prompt=INSIGHTS_SYSTEM, user_prompt=prompt)
    except Exception as exc:
        return _response(500, {"error": f"AI processing failed: {exc}"})

    # Always set a correct timestamp
    result["generatedAt"] = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")

    # Inject pre-computed forecast data (replace any AI placeholder values)
    if "forecast" in requested_types:
        forecast = result.get("forecast")
        if isinstance(forecast, dict):
            forecast["dailyProjection"] = daily_projections
            forecast["projectedBalance"] = projected_balance
        else:
            result["forecast"] = {
                "projectedBalance": projected_balance,
                "dailyProjection": daily_projections,
                "summary": "",
            }

    # Inject pre-computed health score numbers (AI may only have written summary)
    if "spending" in requested_types:
        hs = result.get("healthScore")
        summary = hs.get("summary", "") if isinstance(hs, dict) else ""
        result["healthScore"] = {**health_score, "summary": summary}

    # Ensure required list fields exist
    result.setdefault("spending", [])
    result.setdefault("alerts", [])
    result.setdefault("coaching", [])

    return _response(200, result)
