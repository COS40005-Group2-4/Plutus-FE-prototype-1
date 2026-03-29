variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "tc_table_name" {
  description = "Name of the DynamoDB table for T&C acceptance tracking"
  type        = string
  default     = "plutus-tc-acceptance"
}

variable "data_table_name" {
  description = "Name of the main DynamoDB data table"
  type        = string
  default     = "plutus-data"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
  default     = "../Plutus-backend-prototype-2/function.zip"
}

variable "google_client_id" {
  description = "Google OAuth client ID for JWT validation"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the existing S3 bucket for backups"
  type        = string
  default     = "pluwus-backups"
}

variable "cors_allow_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["https://main.d3eqrozysqvds5.amplifyapp.com", "http://localhost:8080"]
}

# AI Lambda variables
variable "ai_lambda_zip_path" {
  description = "Path to the AI Lambda deployment package"
  type        = string
  default     = "../lambda/package.zip"
}

variable "bedrock_model_id" {
  description = "Bedrock model ID for AI features"
  type        = string
  default     = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
}
