import json
import re
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

    @staticmethod
    def _extract_json(text: str) -> dict:
        """Extract a JSON object from model output that may contain prose or fences."""
        text = text.strip()

        # Strip markdown code fences (```json ... ``` or ``` ... ```)
        if text.startswith("```"):
            text = text.split("\n", 1)[1] if "\n" in text else text[3:]
            text = text.rsplit("```", 1)[0]
            text = text.strip()

        # Try direct parse first
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            pass

        # Model may have added prose before/after the JSON object.
        # Find the outermost { ... } pair using brace counting.
        start = text.find("{")
        if start == -1:
            raise ValueError(f"No JSON object found in Bedrock response: {text[:500]}")

        depth = 0
        in_string = False
        escape = False
        for i in range(start, len(text)):
            ch = text[i]
            if escape:
                escape = False
                continue
            if ch == "\\":
                escape = True
                continue
            if ch == '"':
                in_string = not in_string
                continue
            if in_string:
                continue
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    candidate = text[start : i + 1]
                    try:
                        return json.loads(candidate)
                    except json.JSONDecodeError:
                        break

        raise ValueError(f"Failed to parse Bedrock response as JSON: {text[:500]}")

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
        stop_reason = response_body.get("stop_reason", "")
        if stop_reason == "max_tokens":
            raise ValueError(
                "Bedrock response truncated (hit max_tokens). "
                "Increase max_tokens or simplify the prompt."
            )
        text = response_body["content"][0]["text"]

        return self._extract_json(text)
