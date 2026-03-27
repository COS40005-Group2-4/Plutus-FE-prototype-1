variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "tc_table_name" {
  description = "Name of the DynamoDB table for T&C acceptance tracking"
  type        = string
  default     = "plutus-tc-acceptance"
}
