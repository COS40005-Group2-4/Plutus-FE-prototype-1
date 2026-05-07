# REST API for AI endpoints (separate from main HTTP API)
resource "aws_api_gateway_rest_api" "ai" {
  name        = "plutus-ai-api"
  description = "Plutus AI automation endpoints"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = { Project = "Plutus", Component = "AI" }
}

# /categorize resource
resource "aws_api_gateway_resource" "categorize" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  parent_id   = aws_api_gateway_rest_api.ai.root_resource_id
  path_part   = "categorize"
}

# POST /categorize method
resource "aws_api_gateway_method" "categorize_post" {
  rest_api_id      = aws_api_gateway_rest_api.ai.id
  resource_id      = aws_api_gateway_resource.categorize.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# OPTIONS /categorize for CORS
resource "aws_api_gateway_method" "categorize_options" {
  rest_api_id   = aws_api_gateway_rest_api.ai.id
  resource_id   = aws_api_gateway_resource.categorize.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "categorize_options" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.categorize.id
  http_method = aws_api_gateway_method.categorize_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "categorize_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.categorize.id
  http_method = aws_api_gateway_method.categorize_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "categorize_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.categorize.id
  http_method = aws_api_gateway_method.categorize_options.http_method
  status_code = aws_api_gateway_method_response.categorize_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda integration for POST /categorize
resource "aws_api_gateway_integration" "categorize_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ai.id
  resource_id             = aws_api_gateway_resource.categorize.id
  http_method             = aws_api_gateway_method.categorize_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ai_categorize.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "ai_categorize_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_categorize.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ai.execution_arn}/*/*"
}

# ── /insights resource ──

resource "aws_api_gateway_resource" "insights" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  parent_id   = aws_api_gateway_rest_api.ai.root_resource_id
  path_part   = "insights"
}

# POST /insights method
resource "aws_api_gateway_method" "insights_post" {
  rest_api_id      = aws_api_gateway_rest_api.ai.id
  resource_id      = aws_api_gateway_resource.insights.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# OPTIONS /insights for CORS
resource "aws_api_gateway_method" "insights_options" {
  rest_api_id   = aws_api_gateway_rest_api.ai.id
  resource_id   = aws_api_gateway_resource.insights.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "insights_options" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.insights.id
  http_method = aws_api_gateway_method.insights_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "insights_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.insights.id
  http_method = aws_api_gateway_method.insights_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "insights_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.insights.id
  http_method = aws_api_gateway_method.insights_options.http_method
  status_code = aws_api_gateway_method_response.insights_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda integration for POST /insights
resource "aws_api_gateway_integration" "insights_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ai.id
  resource_id             = aws_api_gateway_resource.insights.id
  http_method             = aws_api_gateway_method.insights_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ai_insights.invoke_arn
}

# Lambda permission for insights endpoint
resource "aws_lambda_permission" "ai_insights_apigw" {
  statement_id  = "AllowAPIGatewayInvokeInsights"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_insights.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ai.execution_arn}/*/*"
}

# ── /report-insights resource ──

resource "aws_api_gateway_resource" "report_insights" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  parent_id   = aws_api_gateway_rest_api.ai.root_resource_id
  path_part   = "report-insights"
}

# POST /report-insights method
resource "aws_api_gateway_method" "report_insights_post" {
  rest_api_id      = aws_api_gateway_rest_api.ai.id
  resource_id      = aws_api_gateway_resource.report_insights.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

# OPTIONS /report-insights for CORS
resource "aws_api_gateway_method" "report_insights_options" {
  rest_api_id   = aws_api_gateway_rest_api.ai.id
  resource_id   = aws_api_gateway_resource.report_insights.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "report_insights_options" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.report_insights.id
  http_method = aws_api_gateway_method.report_insights_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "report_insights_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.report_insights.id
  http_method = aws_api_gateway_method.report_insights_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "report_insights_options_200" {
  rest_api_id = aws_api_gateway_rest_api.ai.id
  resource_id = aws_api_gateway_resource.report_insights.id
  http_method = aws_api_gateway_method.report_insights_options.http_method
  status_code = aws_api_gateway_method_response.report_insights_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda integration for POST /report-insights
resource "aws_api_gateway_integration" "report_insights_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.ai.id
  resource_id             = aws_api_gateway_resource.report_insights.id
  http_method             = aws_api_gateway_method.report_insights_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ai_report_insights.invoke_arn
}

# Lambda permission for report-insights endpoint
resource "aws_lambda_permission" "ai_report_insights_apigw" {
  statement_id  = "AllowAPIGatewayInvokeReportInsights"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ai_report_insights.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ai.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "ai" {
  rest_api_id = aws_api_gateway_rest_api.ai.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.categorize_post,
      aws_api_gateway_method.categorize_options,
      aws_api_gateway_integration.categorize_lambda,
      aws_api_gateway_integration.categorize_options,
      aws_api_gateway_method.insights_post,
      aws_api_gateway_method.insights_options,
      aws_api_gateway_integration.insights_lambda,
      aws_api_gateway_integration.insights_options,
      aws_api_gateway_method.report_insights_post,
      aws_api_gateway_method.report_insights_options,
      aws_api_gateway_integration.report_insights_lambda,
      aws_api_gateway_integration.report_insights_options,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.categorize_lambda,
    aws_api_gateway_integration.categorize_options,
    aws_api_gateway_integration.insights_lambda,
    aws_api_gateway_integration.insights_options,
    aws_api_gateway_integration.report_insights_lambda,
    aws_api_gateway_integration.report_insights_options,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "ai_prod" {
  deployment_id = aws_api_gateway_deployment.ai.id
  rest_api_id   = aws_api_gateway_rest_api.ai.id
  stage_name    = "prod"

  tags = { Project = "Plutus", Component = "AI" }
}

# API Key
resource "aws_api_gateway_api_key" "ai_client" {
  name    = "plutus-ai-client-key"
  enabled = true

  tags = { Project = "Plutus", Component = "AI" }
}

# Usage Plan with throttling
resource "aws_api_gateway_usage_plan" "ai" {
  name = "plutus-ai-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.ai.id
    stage  = aws_api_gateway_stage.ai_prod.stage_name
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }

  tags = { Project = "Plutus", Component = "AI" }
}

# Associate API key with usage plan
resource "aws_api_gateway_usage_plan_key" "ai_client" {
  key_id        = aws_api_gateway_api_key.ai_client.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.ai.id
}
