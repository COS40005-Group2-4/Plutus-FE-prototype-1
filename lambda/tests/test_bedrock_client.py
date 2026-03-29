import json
from unittest.mock import MagicMock, patch

import pytest

from shared.bedrock_client import BedrockClient


class TestBedrockClient:
    def test_invoke_returns_parsed_json(self):
        mock_boto = MagicMock()
        mock_response_body = MagicMock()
        mock_response_body.read.return_value = json.dumps(
            {"content": [{"text": '{"account": "Expenses:Food", "confidence": 0.95}'}]}
        ).encode()
        mock_boto.invoke_model.return_value = {"body": mock_response_body}

        client = BedrockClient(bedrock_client=mock_boto)
        result = client.invoke(
            system_prompt="You are a categorizer.",
            user_prompt="Categorize: Grab 50000 VND",
        )

        assert result == {"account": "Expenses:Food", "confidence": 0.95}
        mock_boto.invoke_model.assert_called_once()

    def test_invoke_raises_on_invalid_json_response(self):
        mock_boto = MagicMock()
        mock_response_body = MagicMock()
        mock_response_body.read.return_value = json.dumps(
            {"content": [{"text": "not valid json"}]}
        ).encode()
        mock_boto.invoke_model.return_value = {"body": mock_response_body}

        client = BedrockClient(bedrock_client=mock_boto)
        with pytest.raises(ValueError, match="Failed to parse"):
            client.invoke(
                system_prompt="You are a categorizer.",
                user_prompt="Categorize this",
            )

    def test_invoke_uses_correct_model_id(self):
        mock_boto = MagicMock()
        mock_response_body = MagicMock()
        mock_response_body.read.return_value = json.dumps(
            {"content": [{"text": '{"result": "ok"}'}]}
        ).encode()
        mock_boto.invoke_model.return_value = {"body": mock_response_body}

        client = BedrockClient(bedrock_client=mock_boto, model_id="anthropic.claude-haiku-4-5-20251001")
        client.invoke(system_prompt="test", user_prompt="test")

        call_kwargs = mock_boto.invoke_model.call_args[1]
        assert call_kwargs["modelId"] == "anthropic.claude-haiku-4-5-20251001"
