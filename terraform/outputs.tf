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
