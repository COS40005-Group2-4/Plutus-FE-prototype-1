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
You are **Plutus Coach** — a certified personal-finance advisor embedded in a Vietnamese budgeting app.

## RESPONSE FORMAT
- Return **ONLY** a single, valid JSON object. No markdown fences, no prose outside the JSON.
- Every `title`, `body`, and `summary` field MUST be written in the **locale language** \
(locale=vi → Vietnamese; locale=en → English).

## FINANCIAL WRITING RULES
1. **Precision**: Quote exact figures from the data provided. Use the user's `currency` symbol. \
Format large numbers with thousand separators (e.g., "1,250,000 VND", "$1,250").
2. **Month-over-Month (MoM) comparisons**: Express changes as signed percentages \
("+12.5%", "−8.3%"). Always state the direction ("increased", "decreased", "unchanged").
3. **Actionable language**: Every insight body MUST include a concrete next step. \
Replace vague advice ("spend less") with specific actions \
("Switch to a no-fee debit card for daily purchases under 200,000 VND").
4. **Severity mapping**: \
"warning" = overspending, budget breach, negative cash-flow trend. \
"info" = neutral observation, seasonal pattern, benchmark comparison. \
"positive" = savings goal met, spending decreased, surplus detected.
5. **Tone**: Professional yet approachable. For Vietnamese locale, use polite "bạn" form. \
Incorporate Vietnam-specific context (Tết spending, gold price references, local bank rates) where relevant.
6. **Brevity**: Titles ≤ 60 characters. Bodies ≤ 3 sentences. Summaries ≤ 2 sentences."""


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
    categories = sorted(
        data.get("categories", []),
        key=lambda c: (c.get("amounts") or [0])[0],
        reverse=True,
    )[:8]
    top_merchants = data.get("topMerchants", [])[:8]

    lang = "Vietnamese" if locale == "vi" else "English"
    net_monthly = avg_income - avg_expense

    # ── Section 1: Financial snapshot ────────────────────────────────────
    lines = [
        f"## USER FINANCIAL SNAPSHOT (as of {current_date})",
        f"- **Locale**: {locale} — write ALL text fields in **{lang}**.",
        f"- **Currency**: {currency}.",
        f"- **Monthly gross income**: {_fmt(avg_income, currency)} (3-month average).",
        f"- **Monthly total expenses**: {_fmt(avg_expense, currency)} (3-month average).",
        f"- **Net monthly cash flow**: {_fmt(net_monthly, currency)} "
        f"({'surplus' if net_monthly >= 0 else 'deficit'}).",
        f"- **Savings rate**: {savings_rate:.1%} of gross income.",
    ]

    # Category breakdown
    if categories:
        lines.append("\n### EXPENSE BREAKDOWN BY CATEGORY (3-month totals)")
        for i, c in enumerate(categories, 1):
            amt = (c.get("amounts") or [0])[0]
            cnt = (c.get("txCount") or [0])[0]
            pct = (amt / avg_expense * 100) if avg_expense > 0 else 0
            lines.append(
                f"  {i}. **{c.get('name', 'Other')}**: "
                f"{_fmt(amt, currency)} ({pct:.1f}% of expenses, {cnt} transactions)."
            )

    # Top merchants
    if top_merchants:
        lines.append("\n### TOP MERCHANTS BY SPEND")
        for m in top_merchants:
            lines.append(
                f"  - **{m.get('name', '')}** [{m.get('category', '')}]: "
                f"{_fmt(m.get('total', 0), currency)} across {m.get('count', 0)} transactions."
            )

    # Health score context
    if health_score:
        comp = health_score["components"]
        lines.append(f"\n### FINANCIAL HEALTH SCORE: **{health_score['score']}/100**")
        lines.append(
            f"  - Savings sub-score: {comp['savings']['score']}/100 "
            f"(rate: {comp['savings']['value']:.1%})."
        )
        lines.append(
            f"  - Consistency sub-score: {comp['consistency']['score']}/100 "
            f"(spending volatility: {'low' if comp['consistency']['score'] >= 70 else 'high'})."
        )
        lines.append(
            f"  - Income-to-expense ratio sub-score: {comp['balance']['score']}/100 "
            f"(ratio: {comp['balance']['value']:.2f}x)."
        )

    # Cash-flow projection context
    if projected_balance:
        lines.append("\n### 30-DAY PROJECTED NET CASH FLOW")
        lines.append(f"  - **Optimistic** (−15% spending): {_fmt(projected_balance['optimistic'], currency)}.")
        lines.append(f"  - **Likely** (baseline): {_fmt(projected_balance['likely'], currency)}.")
        lines.append(f"  - **Pessimistic** (+20% spending): {_fmt(projected_balance['pessimistic'], currency)}.")

    # ── Section 2: Task instructions ─────────────────────────────────────
    want_spending = "spending" in requested_types
    want_forecast = "forecast" in requested_types
    want_alerts = "alerts" in requested_types
    want_coaching = "coaching" in requested_types

    lines.append("\n---")
    lines.append("## YOUR TASK")
    lines.append(
        "Produce a JSON object matching the **exact schema** below. "
        "Replace every `\"<FILL>\"` placeholder with real content derived from the data above."
    )

    schema: dict = {"generatedAt": f"{current_date}T00:00:00.000Z"}

    # ── healthScore: AI writes ONLY the summary ─────────────────────────
    if want_spending and health_score:
        lines.append(
            "\n**healthScore.summary**: Write 1 sentence interpreting the score. "
            "Reference the weakest sub-score by name and suggest one improvement."
        )
        schema["healthScore"] = {
            **health_score,
            "summary": "<FILL: 1-sentence health score interpretation>",
        }
    else:
        schema["healthScore"] = None

    # ── spending: 3 AI-generated insights ────────────────────────────────
    if want_spending:
        lines.append(
            "\n**spending[]**: Generate exactly **3** spending insights:"
        )
        lines.append(
            "  1. `si_1` — **Largest expense category**: Cite the category name, exact amount, "
            "and % of total expenses. Compare MoM if data allows. severity=`warning` if >30% of expenses, "
            "else `info`. metric.label must be a % change string (e.g., \"+18.2% MoM\")."
        )
        lines.append(
            "  2. `si_2` — **Notable spending pattern**: Identify a merchant concentration, "
            "recurring charge, or unusual spike. severity=`warning` or `info`."
        )
        lines.append(
            "  3. `si_3` — **Positive observation**: Highlight a category where spending is "
            "well-controlled, a good savings habit, or an improving trend. severity=`positive`."
        )
        schema["spending"] = [
            {
                "id": "si_1",
                "title": "<FILL: ≤60 chars>",
                "body": "<FILL: 2–3 sentences with exact figures>",
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
                "body": "<FILL>",
                "category": None,
                "metric": None,
            },
            {
                "id": "si_3",
                "title": "<FILL>",
                "body": "<FILL>",
                "category": None,
                "metric": None,
            },
        ]
    else:
        schema["spending"] = []

    # ── forecast: AI writes ONLY the summary ─────────────────────────────
    if want_forecast:
        lines.append(
            "\n**forecast.summary**: Write 1–2 sentences interpreting the 3-scenario projection. "
            "State the likely outcome in currency terms, and flag risk if pessimistic is negative."
        )
        schema["forecast"] = {
            "projectedBalance": projected_balance,
            "dailyProjection": [],
            "summary": "<FILL: 1–2 sentence cash-flow outlook>",
        }
    else:
        schema["forecast"] = None

    # ── alerts: AI-generated smart alerts ────────────────────────────────
    if want_alerts:
        alert_instructions = [
            "\n**alerts[]**: Generate smart alerts based on the data:",
            "  - At least 1 **warning** alert if: savings rate <10%, any category >40% of expenses, "
            "or net cash flow is negative.",
            "  - At least 1 **positive** alert if: savings rate ≥20%, expenses trending down, "
            "or a budget category is well under control.",
            "  - severity must be one of: `warning`, `info`, `positive`.",
            "  - Each alert body must cite the specific metric that triggered it.",
        ]
        lines.extend(alert_instructions)

        alerts_schema = [
            {
                "id": "alert_1",
                "title": "<FILL>",
                "body": "<FILL: cite the triggering metric>",
                "severity": "<FILL: warning|info|positive>",
                "isRead": False,
            },
        ]
        if savings_rate >= 0.15:
            alerts_schema.append({
                "id": "alert_2",
                "title": "<FILL: positive reinforcement>",
                "body": "<FILL: cite savings rate or surplus figure>",
                "severity": "positive",
                "isRead": False,
            })
        schema["alerts"] = alerts_schema
    else:
        schema["alerts"] = []

    # ── coaching: 3 AI-generated actionable tips ─────────────────────────
    if want_coaching:
        lines.append(
            "\n**coaching[]**: Generate exactly **3** personalized coaching tips:"
        )
        lines.append(
            "  1. `tip_1` (difficulty=`easy`): A **quick-win** the user can implement today. "
            "No estimated savings needed."
        )
        lines.append(
            "  2. `tip_2` (difficulty=`medium`): A **savings optimization** with a concrete "
            f"`savingsEstimate` in {currency} (monthly potential). "
            "Base the estimate on the actual spending data provided."
        )
        lines.append(
            "  3. `tip_3` (difficulty=`hard`): A **long-term financial strategy** "
            "(e.g., investment diversification, emergency fund target, debt payoff plan). "
            "No estimated savings needed."
        )
        if locale == "vi":
            lines.append(
                "  For Vietnamese locale: Reference local financial products "
                "(tiết kiệm ngân hàng, vàng SJC, chứng chỉ quỹ) where appropriate."
            )
        schema["coaching"] = [
            {
                "id": "tip_1",
                "title": "<FILL>",
                "body": "<FILL: concrete action step>",
                "savingsEstimate": None,
                "difficulty": "easy",
                "isSaved": False,
            },
            {
                "id": "tip_2",
                "title": "<FILL>",
                "body": "<FILL: include estimated monthly savings>",
                "savingsEstimate": "<FILL: number in currency units>",
                "difficulty": "medium",
                "isSaved": False,
            },
            {
                "id": "tip_3",
                "title": "<FILL>",
                "body": "<FILL: long-term strategy>",
                "savingsEstimate": None,
                "difficulty": "hard",
                "isSaved": False,
            },
        ]
    else:
        schema["coaching"] = []

    # ── Final instruction ────────────────────────────────────────────────
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
            max_tokens=2048,
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
