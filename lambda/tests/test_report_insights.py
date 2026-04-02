import json
import pytest
from unittest.mock import patch, MagicMock

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from report_insights.handler import handler


@pytest.fixture
def valid_event():
    return {
        "body": json.dumps({
            "sections": ["spending_breakdown", "income_analysis"],
            "dateRange": {"start": "2026-03-01", "end": "2026-03-31"},
            "comparisonRange": {"start": "2026-02-01", "end": "2026-02-28"},
            "audienceMode": "personal",
            "locale": "en",
            "privacyLevel": "standard",
            "sectionData": {
                "spending_breakdown": {
                    "categories": [
                        {"name": "Housing", "amount": 950, "percentage": 33.4, "changePercent": 0},
                        {"name": "Groceries", "amount": 632, "percentage": 22.2, "changePercent": 18.1},
                    ],
                    "total": 2847,
                    "comparisonTotal": 3105,
                },
                "income_analysis": {
                    "total": 4230,
                    "comparisonTotal": 4200,
                },
            },
        })
    }


def test_handler_returns_200_with_valid_input(valid_event):
    mock_response = json.dumps({
        "spending_breakdown": {
            "oneLiner": "Groceries spiked 18%.",
            "detailed": "Detailed analysis here.",
        },
        "income_analysis": {
            "oneLiner": "Income is stable.",
            "detailed": "Detailed income analysis.",
        },
    })

    with patch("report_insights.handler.BedrockClient") as MockBedrock:
        mock_client = MagicMock()
        mock_client.invoke.return_value = mock_response
        MockBedrock.return_value = mock_client

        result = handler(valid_event, None)

    assert result["statusCode"] == 200
    body = json.loads(result["body"])
    assert "recommendations" in body
    assert "spending_breakdown" in body["recommendations"]
    assert "income_analysis" in body["recommendations"]
    assert body["recommendations"]["spending_breakdown"]["oneLiner"] == "Groceries spiked 18%."


def test_handler_returns_400_for_missing_sections():
    event = {"body": json.dumps({"dateRange": {"start": "2026-03-01", "end": "2026-03-31"}})}
    result = handler(event, None)
    assert result["statusCode"] == 400


def test_handler_returns_400_for_empty_body():
    event = {"body": "{}"}
    result = handler(event, None)
    assert result["statusCode"] == 400


def test_handler_returns_500_on_bedrock_failure(valid_event):
    with patch("report_insights.handler.BedrockClient") as MockBedrock:
        mock_client = MagicMock()
        mock_client.invoke.side_effect = Exception("Bedrock timeout")
        MockBedrock.return_value = mock_client

        result = handler(valid_event, None)

    assert result["statusCode"] == 500
