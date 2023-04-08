provider "aws" {}

resource "aws_s3_bucket" "chatgpt" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "manifest" {
  bucket = aws_s3_bucket.chatgpt.id
  key    = ".well-known/manifest.json"
  source = var.path_to_manifest
  etag   = filemd5(var.path_to_manifest)
}

resource "aws_s3_bucket_object" "openapi" {
  bucket = aws_s3_bucket.chatgpt.id
  key    = ".well-known/openapi.json"
  source = var.path_to_openapi
  etag   = filemd5(var.path_to_openapi)
}

resource "aws_lambda_function" "chatgpt_lambda" {
  function_name = "chatgpt_lambda"

  filename      = var.path_to_lambda
  handler       = var.lambda_handler
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = var.lambda_runtime
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_apigatewayv2_api" "chatgpt_api" {
  name          = "chatgpt-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "chatgpt_integration" {
  api_id           = aws_apigatewayv2_api.chatgpt_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  integration_uri      = aws_lambda_function.chatgpt_lambda.invoke_arn
  integration_method   = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "chatgpt_route" {
  api_id    = aws_apigatewayv2_api.chatgpt_api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.chatgpt_integration.id}"
}

resource "aws_apigatewayv2_stage" "chatgpt_stage" {
  api_id      = aws_apigatewayv2_api.chatgpt_api.id
  name        = "default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatgpt_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chatgpt_api.execution_arn}/*/*"
}
