# ─────────────────────────────────────────────────────────────
# The HTTP API itself
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"

  # CORS config — API Gateway handles OPTIONS preflight automatically
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 300
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Integration: connect the API to the Lambda
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ─────────────────────────────────────────────────────────────
# Route: GET /count → Lambda
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_route" "this" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ─────────────────────────────────────────────────────────────
# Stage: $default means no /dev or /prod prefix in URL
# ─────────────────────────────────────────────────────────────
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────
# Permission: allow API Gateway to invoke the Lambda
# Without this, you get a 500 error and no clue why.
# ─────────────────────────────────────────────────────────────
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}