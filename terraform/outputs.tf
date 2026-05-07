output "tc_table_name" {
  value = aws_dynamodb_table.tc_acceptance.name
}

output "tc_table_arn" {
  value = aws_dynamodb_table.tc_acceptance.arn
}

output "data_table_name" {
  value = aws_dynamodb_table.plutus_data.name
}

output "data_table_arn" {
  value = aws_dynamodb_table.plutus_data.arn
}

output "api_gateway_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}

output "lambda_function_name" {
  value = aws_lambda_function.plutus_api.function_name
}

output "ai_api_gateway_url" {
  description = "AI API Gateway invoke URL"
  value       = aws_api_gateway_stage.ai_prod.invoke_url
}

output "ai_api_key_id" {
  description = "AI API key ID (retrieve value via AWS console or CLI)"
  value       = aws_api_gateway_api_key.ai_client.id
}

output "insights_function_url" {
  description = "Lambda Function URL for insights (no API Gateway timeout)"
  value       = aws_lambda_function_url.ai_insights.function_url
}

output "plutus_secret_arn" {
  description = "ARN of the Plutus Secrets Manager secret"
  value       = aws_secretsmanager_secret.plutus.arn
}

output "insights_bearer_token" {
  description = "Bearer token for the insights Lambda Function URL — add to app.env as INSIGHTS_BEARER_TOKEN"
  value       = random_password.insights_bearer_token.result
  sensitive   = true
}
