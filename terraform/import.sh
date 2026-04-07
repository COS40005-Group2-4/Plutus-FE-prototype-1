#!/bin/bash
# Terraform import script for existing Plutus infrastructure
# Run from the terraform/ directory with: AWS_PROFILE=AWS bash import.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1
export AWS_PROFILE=AWS

echo "=== Initializing Terraform ==="
terraform init -upgrade

echo ""
echo "=== Importing DynamoDB Tables ==="
terraform import aws_dynamodb_table.tc_acceptance plutus-tc-acceptance
terraform import aws_dynamodb_table.plutus_data plutus-data

echo ""
echo "=== Importing S3 CORS Configuration ==="
terraform import aws_s3_bucket_cors_configuration.backups pluwus-backups

echo ""
echo "=== Importing IAM Roles ==="
terraform import aws_iam_role.lambda_exec plutus-api-lambda-role
terraform import aws_iam_role.ai_lambda_exec plutus-ai-lambda-role
terraform import aws_iam_role.ai_insights_role plutus-ai-insights-role
terraform import aws_iam_role.ai_report_insights_role plutus-ai-report-insights-role

echo ""
echo "=== Importing IAM Role Policies ==="
terraform import aws_iam_role_policy.lambda_dynamodb plutus-api-lambda-role:plutus-lambda-dynamodb
terraform import aws_iam_role_policy.lambda_s3 plutus-api-lambda-role:plutus-lambda-s3
terraform import aws_iam_role_policy.ai_lambda_bedrock plutus-ai-lambda-role:plutus-ai-bedrock-invoke
terraform import aws_iam_role_policy.ai_insights_bedrock plutus-ai-insights-role:plutus-ai-insights-bedrock
terraform import aws_iam_role_policy.ai_report_insights_bedrock plutus-ai-report-insights-role:plutus-ai-report-insights-bedrock

echo ""
echo "=== Importing IAM Role Policy Attachments ==="
terraform import aws_iam_role_policy_attachment.lambda_logs "plutus-api-lambda-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
terraform import aws_iam_role_policy_attachment.ai_lambda_logs "plutus-ai-lambda-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
terraform import aws_iam_role_policy_attachment.ai_insights_logs "plutus-ai-insights-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
terraform import aws_iam_role_policy_attachment.ai_report_insights_logs "plutus-ai-report-insights-role/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

echo ""
echo "=== Importing Lambda Functions ==="
terraform import aws_lambda_function.plutus_api plutus-api
terraform import aws_lambda_function.ai_categorize plutus-ai-categorize
terraform import aws_lambda_function.ai_insights plutus-ai-insights
terraform import aws_lambda_function.ai_report_insights plutus-report-insights

echo ""
echo "=== Importing Lambda Layer ==="
terraform import aws_lambda_layer_version.ai_shared "arn:aws:lambda:ap-southeast-1:600627340244:layer:plutus-ai-shared:11"

echo ""
echo "=== Importing CloudWatch Log Groups ==="
terraform import aws_cloudwatch_log_group.lambda_logs "/aws/lambda/plutus-api"
terraform import aws_cloudwatch_log_group.ai_categorize "/aws/lambda/plutus-ai-categorize"
terraform import aws_cloudwatch_log_group.api_gateway_logs "/aws/apigateway/plutus-api"

echo ""
echo "=== Importing HTTP API Gateway (plutus-api) ==="
terraform import aws_apigatewayv2_api.plutus iw68fbk44c
terraform import aws_apigatewayv2_authorizer.google_jwt iw68fbk44c/2nsi5t
terraform import aws_apigatewayv2_integration.lambda iw68fbk44c/cxry2mr
terraform import aws_apigatewayv2_stage.default iw68fbk44c/\$default

echo ""
echo "=== Importing HTTP API Routes ==="
terraform import 'aws_apigatewayv2_route.routes["GET /investments/{id}"]' iw68fbk44c/4wwtjfi
terraform import 'aws_apigatewayv2_route.routes["POST /transactions"]' iw68fbk44c/66rzm9m
terraform import 'aws_apigatewayv2_route.routes["POST /investments"]' iw68fbk44c/8dtnsxd
terraform import 'aws_apigatewayv2_route.routes["POST /backups"]' iw68fbk44c/b5405t6
terraform import 'aws_apigatewayv2_route.routes["POST /backups/restore"]' iw68fbk44c/da4q5rs
terraform import 'aws_apigatewayv2_route.routes["GET /consent"]' iw68fbk44c/dmxyjac
terraform import 'aws_apigatewayv2_route.routes["GET /transactions"]' iw68fbk44c/geibhqr
terraform import 'aws_apigatewayv2_route.routes["DELETE /investments/{id}"]' iw68fbk44c/kvuzmuh
terraform import 'aws_apigatewayv2_route.routes["GET /reports/roi"]' iw68fbk44c/lplo3x2
terraform import 'aws_apigatewayv2_route.routes["POST /consent"]' iw68fbk44c/mdgsvr8
terraform import 'aws_apigatewayv2_route.routes["PUT /investments/{id}"]' iw68fbk44c/njp21qf
terraform import 'aws_apigatewayv2_route.routes["POST /import"]' iw68fbk44c/o7btwl0
terraform import 'aws_apigatewayv2_route.routes["GET /backups"]' iw68fbk44c/pf8disj
terraform import 'aws_apigatewayv2_route.routes["GET /reports/income"]' iw68fbk44c/yiq3zwd
terraform import 'aws_apigatewayv2_route.routes["GET /investments"]' iw68fbk44c/z5ck4bf

echo ""
echo "=== Importing Lambda Permissions ==="
terraform import aws_lambda_permission.api_gateway plutus-api/AllowAPIGateway
terraform import aws_lambda_permission.ai_categorize_apigw plutus-ai-categorize/AllowAPIGatewayInvoke
terraform import aws_lambda_permission.ai_insights_apigw plutus-ai-insights/AllowAPIGatewayInvokeInsights
terraform import aws_lambda_permission.ai_report_insights_apigw plutus-report-insights/AllowAPIGatewayInvokeReportInsights

echo ""
echo "=== Importing REST API Gateway (plutus-ai-api) ==="
terraform import aws_api_gateway_rest_api.ai ok9ke6kx5g

# /categorize resources
terraform import aws_api_gateway_resource.categorize ok9ke6kx5g/prlc4f
terraform import aws_api_gateway_method.categorize_post ok9ke6kx5g/prlc4f/POST
terraform import aws_api_gateway_method.categorize_options ok9ke6kx5g/prlc4f/OPTIONS
terraform import aws_api_gateway_integration.categorize_lambda ok9ke6kx5g/prlc4f/POST
terraform import aws_api_gateway_integration.categorize_options ok9ke6kx5g/prlc4f/OPTIONS
terraform import aws_api_gateway_method_response.categorize_options_200 ok9ke6kx5g/prlc4f/OPTIONS/200
terraform import aws_api_gateway_integration_response.categorize_options_200 ok9ke6kx5g/prlc4f/OPTIONS/200

# /insights resources
terraform import aws_api_gateway_resource.insights ok9ke6kx5g/f3d3d7
terraform import aws_api_gateway_method.insights_post ok9ke6kx5g/f3d3d7/POST
terraform import aws_api_gateway_method.insights_options ok9ke6kx5g/f3d3d7/OPTIONS
terraform import aws_api_gateway_integration.insights_lambda ok9ke6kx5g/f3d3d7/POST
terraform import aws_api_gateway_integration.insights_options ok9ke6kx5g/f3d3d7/OPTIONS
terraform import aws_api_gateway_method_response.insights_options_200 ok9ke6kx5g/f3d3d7/OPTIONS/200
terraform import aws_api_gateway_integration_response.insights_options_200 ok9ke6kx5g/f3d3d7/OPTIONS/200

# /report-insights resources
terraform import aws_api_gateway_resource.report_insights ok9ke6kx5g/6pbviv
terraform import aws_api_gateway_method.report_insights_post ok9ke6kx5g/6pbviv/POST
terraform import aws_api_gateway_method.report_insights_options ok9ke6kx5g/6pbviv/OPTIONS
terraform import aws_api_gateway_integration.report_insights_lambda ok9ke6kx5g/6pbviv/POST
terraform import aws_api_gateway_integration.report_insights_options ok9ke6kx5g/6pbviv/OPTIONS
terraform import aws_api_gateway_method_response.report_insights_options_200 ok9ke6kx5g/6pbviv/OPTIONS/200
terraform import aws_api_gateway_integration_response.report_insights_options_200 ok9ke6kx5g/6pbviv/OPTIONS/200

# Deployment, stage, API key, usage plan
terraform import aws_api_gateway_deployment.ai ok9ke6kx5g/2rsgfk
terraform import aws_api_gateway_stage.ai_prod ok9ke6kx5g/prod
terraform import aws_api_gateway_api_key.ai_client zy05dnxs2i
terraform import aws_api_gateway_usage_plan.ai ql4luo
terraform import aws_api_gateway_usage_plan_key.ai_client "ql4luo/zy05dnxs2i"

echo ""
echo "=== Import complete! Run 'terraform plan' to verify ==="
