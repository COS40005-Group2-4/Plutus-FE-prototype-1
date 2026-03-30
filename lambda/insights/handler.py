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


INSIGHTS_SYSTEM = """You are Plutus Coach, a personal finance advisor for Vietnamese users.
Return ONLY a valid JSON object. No markdown code fences, no text outside the JSON.
Generate all title/body/summary fields in the locale language (vi=Vietnamese, en=English).
Be concise (2-3 sentences max per body), actionable, and culturally appropriate for Vietnam."""


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
    daily_exp_opt = daily_exp_likely * 0.85   # -15 % spending
    daily_exp_pess = daily_exp_likely * 1.20  # +20 % spending

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
    )[:6]
    top_merchants = data.get("topMerchants", [])[:5]

    lang_hint = f"in {locale}"

    ctx = [
        f"locale={locale} currency={currency} date={current_date}",
        f"monthly_income={avg_income:,.0f} monthly_expense={avg_expense:,.0f} savings_rate={savings_rate:.1%}",
    ]
    if categories:
        cats = ", ".join(
            f"{c.get('name', 'Other')}={(c.get('amounts') or [0])[0]:,.0f}"
            for c in categories
        )
        ctx.append(f"top_categories: {cats}")
    if top_merchants:
        merchs = ", ".join(
            f"{m.get('name', '')}={m.get('total', 0):,.0f}" for m in top_merchants
        )
        ctx.append(f"top_merchants: {merchs}")
    if health_score:
        comp = health_score["components"]
        ctx.append(
            f"health_score={health_score['score']}/100 "
            f"(savings={comp['savings']['score']}, "
            f"consistency={comp['consistency']['score']}, "
            f"balance={comp['balance']['score']})"
        )
    if projected_balance:
        ctx.append(
            f"30d_net_cashflow: optimistic={projected_balance['optimistic']:+,.0f} "
            f"likely={projected_balance['likely']:+,.0f} "
            f"pessimistic={projected_balance['pessimistic']:+,.0f} {currency}"
        )

    want_spending = "spending" in requested_types
    want_forecast = "forecast" in requested_types
    want_alerts = "alerts" in requested_types
    want_coaching = "coaching" in requested_types

    schema: dict = {"generatedAt": f"{current_date}T00:00:00.000Z"}

    # healthScore — numbers are pre-computed; AI writes only "summary"
    schema["healthScore"] = (
        {**health_score, "summary": f"<1-sentence health summary {lang_hint}>"}
        if want_spending
        else None
    )

    # spending — fully AI-generated (3 insights)
    schema["spending"] = (
        [
            {
                "id": "si_1",
                "title": f"<spending insight title {lang_hint}>",
                "body": f"<2-3 sentence insight {lang_hint}>",
                "category": "<top spending category name or null>",
                "metric": {
                    "label": "<change label e.g. +18% vs last month>",
                    "direction": "up",
                    "severity": "warning",
                },
            },
            {
                "id": "si_2",
                "title": f"<another spending insight title {lang_hint}>",
                "body": f"<2-3 sentence insight {lang_hint}>",
                "category": None,
                "metric": None,
            },
            {
                "id": "si_3",
                "title": f"<positive spending observation title {lang_hint}>",
                "body": f"<2-3 sentence positive highlight {lang_hint}>",
                "category": None,
                "metric": None,
            },
        ]
        if want_spending
        else []
    )

    # forecast — numbers pre-computed; AI writes only "summary"; dailyProjection injected after call
    schema["forecast"] = (
        {
            "projectedBalance": projected_balance,
            "dailyProjection": [],
            "summary": f"<1-2 sentence 30-day cash-flow outlook {lang_hint}>",
        }
        if want_forecast
        else None
    )

    # alerts — fully AI-generated
    if want_alerts:
        alerts = [
            {
                "id": "alert_1",
                "title": f"<alert title {lang_hint}>",
                "body": f"<alert body {lang_hint}>",
                "severity": "warning",
                "isRead": False,
            }
        ]
        if savings_rate >= 0.2:
            alerts.append(
                {
                    "id": "alert_2",
                    "title": f"<positive alert title {lang_hint}>",
                    "body": f"<positive reinforcement {lang_hint}>",
                    "severity": "positive",
                    "isRead": False,
                }
            )
        schema["alerts"] = alerts
    else:
        schema["alerts"] = []

    # coaching — fully AI-generated (3 tips)
    schema["coaching"] = (
        [
            {
                "id": "tip_1",
                "title": f"<quick-win tip title {lang_hint}>",
                "body": f"<2-3 sentence practical tip {lang_hint}>",
                "savingsEstimate": None,
                "difficulty": "easy",
                "isSaved": False,
            },
            {
                "id": "tip_2",
                "title": f"<savings tip title {lang_hint}>",
                "body": f"<2-3 sentence tip with estimated savings {lang_hint}>",
                "savingsEstimate": 200000,
                "difficulty": "medium",
                "isSaved": False,
            },
            {
                "id": "tip_3",
                "title": f"<long-term financial tip title {lang_hint}>",
                "body": f"<2-3 sentence long-term advice {lang_hint}>",
                "savingsEstimate": None,
                "difficulty": "hard",
                "isSaved": False,
            },
        ]
        if want_coaching
        else []
    )

    ctx.append("\nFill in all <...> placeholders with real insight content. Return ONLY this JSON:")
    ctx.append(json.dumps(schema, ensure_ascii=False, indent=2))
    return "\n".join(ctx)


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
