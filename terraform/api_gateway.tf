resource "aws_apigatewayv2_api" "plutus" {
  name          = "plutus-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type"]
    max_age       = 3600
  }

  tags = {
    Project = "Plutus"
  }
}

# JWT Authorizer for Google OAuth
resource "aws_apigatewayv2_authorizer" "google_jwt" {
  api_id           = aws_apigatewayv2_api.plutus.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "google-jwt"

  jwt_configuration {
    audience = [var.google_client_id]
    issuer   = "https://accounts.google.com"
  }
}

# Lambda integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.plutus.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.plutus_api.invoke_arn
  payload_format_version = "2.0"
}

# Routes
locals {
  routes = {
    "POST /import"             = "POST /import"
    "GET /reports/income"      = "GET /reports/income"
    "GET /transactions"        = "GET /transactions"
    "POST /transactions"       = "POST /transactions"
    "GET /reports/roi"         = "GET /reports/roi"
    "GET /investments"         = "GET /investments"
    "GET /investments/{id}"    = "GET /investments/{id}"
    "POST /investments"        = "POST /investments"
    "PUT /investments/{id}"    = "PUT /investments/{id}"
    "DELETE /investments/{id}" = "DELETE /investments/{id}"
    "POST /backups"            = "POST /backups"
    "GET /backups"             = "GET /backups"
    "POST /backups/restore"    = "POST /backups/restore"
    "POST /consent"            = "POST /consent"
    "GET /consent"             = "GET /consent"
  }
}

resource "aws_apigatewayv2_route" "routes" {
  for_each = local.routes

  api_id             = aws_apigatewayv2_api.plutus.id
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.google_jwt.id
}

# Auto-deploy stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.plutus.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Project = "Plutus"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/plutus-api"
  retention_in_days = 14
  tags = {
    Project = "Plutus"
  }
}
