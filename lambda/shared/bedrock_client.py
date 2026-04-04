import json
from typing import Any

import boto3


class BedrockClient:
    """Wrapper for Amazon Bedrock model invocation."""

    DEFAULT_MODEL_ID = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
    DEFAULT_MAX_TOKENS = 4096

    def __init__(
        self,
        bedrock_client: Any = None,
        model_id: str = DEFAULT_MODEL_ID,
        region: str = "ap-southeast-1",
        max_tokens: int = DEFAULT_MAX_TOKENS,
    ) -> None:
        self._client = bedrock_client or boto3.client(
            "bedrock-runtime", region_name=region
        )
        self._model_id = model_id
        self._max_tokens = max_tokens

    def invoke(self, system_prompt: str, user_prompt: str) -> dict:
        """Send a prompt to Bedrock and return the parsed JSON response."""
        body = json.dumps(
            {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": self._max_tokens,
                "system": system_prompt,
                "messages": [{"role": "user", "content": user_prompt}],
            }
        )

        response = self._client.invoke_model(
            modelId=self._model_id,
            contentType="application/json",
            accept="application/json",
            body=body,
        )

        response_body = json.loads(response["body"].read())
        text = response_body["content"][0]["text"].strip()

        # Strip markdown code fences if the model wraps its JSON response
        if text.startswith("```"):
            text = text.split("\n", 1)[1]  # remove opening ```json
            text = text.rsplit("```", 1)[0]  # remove closing ```
            text = text.strip()

        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Failed to parse Bedrock response as JSON: {text}") from exc
