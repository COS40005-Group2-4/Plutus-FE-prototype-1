import json
from unittest.mock import MagicMock, patch

import pytest

from categorize.handler import handler


class TestCategorizeHandler:
    def _make_event(self, body: dict) -> dict:
        return {
            "body": json.dumps(body),
            "headers": {"x-api-key": "test-key"},
        }

    @patch("categorize.handler.BedrockClient")
    def test_returns_category_on_valid_input(self, MockClient):
        mock_instance = MockClient.return_value
        mock_instance.invoke.return_value = {
            "account": "Expenses:Food:Groceries",
            "confidence": 0.92,
        }

        event = self._make_event(
            {
                "transaction": {
                    "payee": "Vinmart",
                    "description": "Weekly groceries",
                    "amount": 250000,
                    "currency": "VND",
                },
                "accounts": [
                    "Expenses:Food:Groceries",
                    "Expenses:Transport",
                    "Expenses:Entertainment",
                ],
                "corrections": [],
            }
        )

        response = handler(event, None)
        body = json.loads(response["body"])

        assert response["statusCode"] == 200
        assert body["account"] == "Expenses:Food:Groceries"
        assert body["confidence"] == 0.92

    def test_returns_400_on_missing_body(self):
        event = {"body": None, "headers": {}}

        response = handler(event, None)

        assert response["statusCode"] == 400
        body = json.loads(response["body"])
        assert "error" in body

    @patch("categorize.handler.BedrockClient")
    def test_returns_500_on_bedrock_error(self, MockClient):
        mock_instance = MockClient.return_value
        mock_instance.invoke.side_effect = Exception("Bedrock timeout")

        event = self._make_event(
            {
                "transaction": {"payee": "Test", "description": "", "amount": 100, "currency": "VND"},
                "accounts": ["Expenses:Other"],
                "corrections": [],
            }
        )

        response = handler(event, None)

        assert response["statusCode"] == 500
        body = json.loads(response["body"])
        assert "error" in body

    @patch("categorize.handler.BedrockClient")
    def test_passes_corrections_to_prompt(self, MockClient):
        mock_instance = MockClient.return_value
        mock_instance.invoke.return_value = {
            "account": "Expenses:Transport",
            "confidence": 0.88,
        }

        event = self._make_event(
            {
                "transaction": {"payee": "Grab", "description": "Ride", "amount": 50000, "currency": "VND"},
                "accounts": ["Expenses:Transport", "Expenses:Food:Dining"],
                "corrections": [
                    {"payee": "Grab", "ai_suggested": "Expenses:Food:Dining", "user_chose": "Expenses:Transport"}
                ],
            }
        )

        response = handler(event, None)
        body = json.loads(response["body"])

        assert response["statusCode"] == 200
        assert body["account"] == "Expenses:Transport"
