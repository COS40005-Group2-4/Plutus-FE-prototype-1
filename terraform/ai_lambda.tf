data "aws_caller_identity" "current" {}

# IAM Role for AI Lambda functions
resource "aws_iam_role" "ai_lambda_exec" {
  name = "plutus-ai-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Project = "Plutus", Component = "AI" }
}

# CloudWatch Logs policy
resource "aws_iam_role_policy_attachment" "ai_lambda_logs" {
  role       = aws_iam_role.ai_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Bedrock invoke policy
resource "aws_iam_role_policy" "ai_lambda_bedrock" {
  name = "plutus-ai-bedrock-invoke"
  role = aws_iam_role.ai_lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = [
        "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.bedrock_model_id}",
        "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"
      ]
    }]
  })
}

# Shared Lambda Layer (shared/ directory)
resource "aws_lambda_layer_version" "ai_shared" {
  filename            = "${var.ai_lambda_zip_path}"
  layer_name          = "plutus-ai-shared"
  compatible_runtimes = ["python3.12"]
  description         = "Shared code for Plutus AI Lambda functions"

  source_code_hash = filebase64sha256(var.ai_lambda_zip_path)
}

# Categorize Lambda function
resource "aws_lambda_function" "ai_categorize" {
  function_name = "plutus-ai-categorize"
  role          = aws_iam_role.ai_lambda_exec.arn
  handler       = "categorize.handler.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 256

  filename         = var.ai_lambda_zip_path
  source_code_hash = filebase64sha256(var.ai_lambda_zip_path)

  layers = [aws_lambda_layer_version.ai_shared.arn]

  environment {
    variables = {
      AWS_REGION_NAME  = var.aws_region
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }

  tags = { Project = "Plutus", Component = "AI", Feature = "categorize" }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ai_categorize" {
  name              = "/aws/lambda/${aws_lambda_function.ai_categorize.function_name}"
  retention_in_days = 14

  tags = { Project = "Plutus", Component = "AI" }
}

# ── Insights Lambda ──

resource "aws_iam_role" "ai_insights_role" {
  name = "plutus-ai-insights-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Project = "Plutus", Component = "AI" }
}

resource "aws_iam_role_policy_attachment" "ai_insights_logs" {
  role       = aws_iam_role.ai_insights_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ai_insights_bedrock" {
  name = "plutus-ai-insights-bedrock"
  role = aws_iam_role.ai_insights_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.insights_bedrock_model_id}",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "ai_insights" {
  function_name = "plutus-ai-insights"
  role          = aws_iam_role.ai_insights_role.arn
  handler       = "insights.handler.handler"
  runtime       = "python3.12"
  memory_size   = 512
  timeout       = 60

  filename         = var.ai_lambda_zip_path
  source_code_hash = filebase64sha256(var.ai_lambda_zip_path)

  layers = [aws_lambda_layer_version.ai_shared.arn]

  environment {
    variables = {
      AWS_REGION_NAME  = var.aws_region
      BEDROCK_MODEL_ID = var.insights_bedrock_model_id
    }
  }

  tags = { Project = "Plutus", Component = "AI" }
}

# ── Report Insights Lambda ──

resource "aws_iam_role" "ai_report_insights_role" {
  name = "plutus-ai-report-insights-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Project = "Plutus", Component = "AI" }
}

resource "aws_iam_role_policy_attachment" "ai_report_insights_logs" {
  role       = aws_iam_role.ai_report_insights_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ai_report_insights_bedrock" {
  name = "plutus-ai-report-insights-bedrock"
  role = aws_iam_role.ai_report_insights_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.insights_bedrock_model_id}",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "ai_report_insights" {
  function_name = "plutus-report-insights"
  role          = aws_iam_role.ai_report_insights_role.arn
  handler       = "report_insights.handler.handler"
  runtime       = "python3.12"
  memory_size   = 512
  timeout       = 60

  filename         = var.ai_lambda_zip_path
  source_code_hash = filebase64sha256(var.ai_lambda_zip_path)

  layers = [aws_lambda_layer_version.ai_shared.arn]

  environment {
    variables = {
      AWS_REGION_NAME  = var.aws_region
      BEDROCK_MODEL_ID = var.insights_bedrock_model_id
    }
  }

  tags = { Project = "Plutus", Component = "AI" }
}
