# IAM role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "plutus-api-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policy for DynamoDB access (both tables)
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "plutus-lambda-dynamodb"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
        "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan",
        "dynamodb:BatchWriteItem", "dynamodb:BatchGetItem"
      ]
      Resource = [
        aws_dynamodb_table.plutus_data.arn,
        "${aws_dynamodb_table.plutus_data.arn}/index/*",
        aws_dynamodb_table.tc_acceptance.arn
      ]
    }]
  })
}

# Policy for S3 access (existing bucket)
resource "aws_iam_role_policy" "lambda_s3" {
  name = "plutus-lambda-s3"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
      Resource = [
        data.aws_s3_bucket.backups.arn,
        "${data.aws_s3_bucket.backups.arn}/*"
      ]
    }]
  })
}

# CloudWatch logs policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "plutus_api" {
  function_name = "plutus-api"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "bootstrap"
  runtime       = "provided.al2023"
  architectures = ["arm64"]
  filename      = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      DATA_TABLE_NAME = aws_dynamodb_table.plutus_data.name
      TC_TABLE_NAME   = aws_dynamodb_table.tc_acceptance.name
      S3_BUCKET_NAME  = data.aws_s3_bucket.backups.id
      GOOGLE_CLIENT_ID = var.google_client_id
    }
  }

  tags = {
    Project = "Plutus"
  }
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.plutus_api.function_name}"
  retention_in_days = 14
  tags = {
    Project = "Plutus"
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.plutus_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.plutus.execution_arn}/*/*"
}
