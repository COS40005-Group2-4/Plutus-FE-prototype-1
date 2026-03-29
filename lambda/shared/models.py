from pydantic import BaseModel, Field


class TransactionInput(BaseModel):
    payee: str = ""
    description: str = ""
    amount: float = 0.0
    currency: str = "VND"


class CorrectionInput(BaseModel):
    payee: str = ""
    ai_suggested: str = ""
    user_chose: str = ""


class CategorizeRequest(BaseModel):
    transaction: TransactionInput
    accounts: list[str] = Field(default_factory=list)
    corrections: list[CorrectionInput] = Field(default_factory=list)


class CategorizeResponse(BaseModel):
    account: str
    confidence: float = Field(ge=0.0, le=1.0)


class ErrorResponse(BaseModel):
    error: str
