import json
import os
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


REPORT_SYSTEM = """\
You are **Plutus Report Analyst** — a certified personal-finance advisor generating \
section-specific recommendations for a financial report.

## RESPONSE FORMAT
- Return **ONLY** a single, valid JSON object. No markdown fences, no prose outside the JSON.
- The JSON object must have one key per requested section.
- Each section value is an object with exactly two fields:
  - "oneLiner": A single sentence (≤ 100 characters) summarizing the key takeaway.
  - "detailed": A 3-5 sentence analysis with specific numbers, comparisons, and actionable advice.

## WRITING RULES
1. **Precision**: Quote exact figures from the data provided. Use the user's currency.
2. **MoM comparisons**: Express changes as signed percentages ("+12.5%", "−8.3%").
3. **Actionable**: Every "detailed" field MUST include at least one concrete next step.
4. **Audience-aware**: For "personal" mode, use casual "you/your" language. \
For "professional" mode, use formal third-person language ("the account holder").
5. **Locale**: Write in the requested locale language (en=English, vi=Vietnamese).
6. **Brevity**: oneLiner ≤ 100 chars. detailed ≤ 5 sentences."""


def _build_prompt(body: dict) -> str:
    sections = body["sections"]
    date_range = body.get("dateRange", {})
    comparison_range = body.get("comparisonRange", {})
    audience = body.get("audienceMode", "personal")
    locale = body.get("locale", "en")
    section_data = body.get("sectionData", {})

    lines = [
        f"**Report period**: {date_range.get('start', '?')} to {date_range.get('end', '?')}",
        f"**Comparison period**: {comparison_range.get('start', '?')} to {comparison_range.get('end', '?')}",
        f"**Audience mode**: {audience}",
        f"**Locale**: {locale}",
        "",
        "## Section Data",
    ]

    for section in sections:
        data = section_data.get(section, {})
        lines.append(f"\n### {section}")
        lines.append(json.dumps(data, indent=2, ensure_ascii=False))

    lines.append(f"\n## Requested Sections: {json.dumps(sections)}")
    lines.append("\nGenerate the JSON response now.")

    return "\n".join(lines)


def handler(event: dict, context: Any) -> dict:
    try:
        raw_body = event.get("body", "{}")
        body = json.loads(raw_body) if isinstance(raw_body, str) else raw_body
    except (json.JSONDecodeError, TypeError):
        return _response(400, {"error": "Invalid JSON body"})

    sections = body.get("sections")
    if not sections:
        return _response(400, {"error": "Missing required field: sections"})

    try:
        client = BedrockClient()
        prompt = _build_prompt(body)
        raw = client.invoke(system=REPORT_SYSTEM, prompt=prompt)

        cleaned = raw.strip()
        if cleaned.startswith("```"):
            cleaned = cleaned.split("\n", 1)[1]
            if cleaned.endswith("```"):
                cleaned = cleaned[: cleaned.rfind("```")]
            cleaned = cleaned.strip()

        recommendations = json.loads(cleaned)

        return _response(200, {"recommendations": recommendations})

    except json.JSONDecodeError as e:
        return _response(500, {"error": f"Failed to parse AI response: {e}"})
    except Exception as e:
        return _response(500, {"error": str(e)})
