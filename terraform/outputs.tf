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
