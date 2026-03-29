import json
import os
from typing import Any

from shared.bedrock_client import BedrockClient
from shared.models import CategorizeRequest, CategorizeResponse, ErrorResponse
from shared.prompts import CATEGORIZE_SYSTEM, build_categorize_prompt


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body),
    }


def handler(event: dict, context: Any) -> dict:
    """Lambda handler for POST /categorize."""
    try:
        raw_body = event.get("body")
        if not raw_body:
            return _response(400, ErrorResponse(error="Missing request body").model_dump())

        request = CategorizeRequest.model_validate_json(raw_body)
    except Exception as exc:
        return _response(400, ErrorResponse(error=f"Invalid request: {exc}").model_dump())

    try:
        client = BedrockClient(
            region=os.environ.get("AWS_REGION", "ap-southeast-1"),
        )

        user_prompt = build_categorize_prompt(
            payee=request.transaction.payee,
            description=request.transaction.description,
            amount=request.transaction.amount,
            currency=request.transaction.currency,
            accounts=request.accounts,
            corrections=[c.model_dump() for c in request.corrections] if request.corrections else None,
        )

        result = client.invoke(
            system_prompt=CATEGORIZE_SYSTEM,
            user_prompt=user_prompt,
        )

        response = CategorizeResponse.model_validate(result)
        return _response(200, response.model_dump())

    except Exception as exc:
        return _response(500, ErrorResponse(error=f"AI processing failed: {exc}").model_dump())
