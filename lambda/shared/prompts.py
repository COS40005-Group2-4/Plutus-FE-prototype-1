CATEGORIZE_SYSTEM = """You are a financial transaction categorizer for a personal finance app that supports English and Vietnamese.

You will receive a transaction (payee, description, amount, currency) and a list of the user's existing accounts.

Rules:
1. Return ONLY a JSON object: {"account": "<account>", "confidence": <0.0-1.0>}
2. The "account" MUST be one of the accounts from the provided list. Never invent new accounts.
3. If no account is a good match, return the account "Expenses:Uncategorized" with confidence below 0.3.
4. Confidence reflects how certain you are: >0.8 = strong match, 0.5-0.8 = reasonable guess, <0.5 = low confidence.
5. Consider Vietnamese merchant names and spending patterns (e.g., "Grab" = Transport, "Vinmart" = Groceries).
6. Do NOT return any text outside the JSON object."""


def build_categorize_prompt(
    payee: str,
    description: str,
    amount: float,
    currency: str,
    accounts: list[str],
    corrections: list[dict] | None = None,
) -> str:
    """Build the user prompt for transaction categorization."""
    parts = [
        f"Transaction: payee={payee}, description={description}, amount={amount}, currency={currency}",
        f"\nUser's accounts:\n{chr(10).join(f'- {a}' for a in accounts)}",
    ]

    if corrections:
        examples = "\n".join(
            f"- payee={c['payee']}: AI suggested '{c['ai_suggested']}', user corrected to '{c['user_chose']}'"
            for c in corrections[-10:]  # Last 10 corrections as few-shot
        )
        parts.append(f"\nPast corrections (learn from these):\n{examples}")

    parts.append("\nReturn only the JSON object.")
    return "\n".join(parts)
