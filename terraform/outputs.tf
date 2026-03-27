output "tc_table_name" {
  description = "Name of the T&C acceptance DynamoDB table"
  value       = aws_dynamodb_table.tc_acceptance.name
}

output "tc_table_arn" {
  description = "ARN of the T&C acceptance DynamoDB table"
  value       = aws_dynamodb_table.tc_acceptance.arn
}
