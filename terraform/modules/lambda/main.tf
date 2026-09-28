# ─────────────────────────────────────────────────────────────
# Package the source code into a zip
# ─────────────────────────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/build/${var.function_name}.zip"
}

# ─────────────────────────────────────────────────────────────
# IAM: assume role for Lambda
# ─────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# ─────────────────────────────────────────────────────────────
# IAM: permissions the Lambda actually needs
# ─────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "lambda_permissions" {
  # CloudWatch Logs — write logs
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  # DynamoDB — only the specific table, only the ops we need
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
    ]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.function_name}-policy"
  policy = data.aws_iam_policy_document.lambda_permissions.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

# ─────────────────────────────────────────────────────────────
# CloudWatch Log Group (with retention so logs don't pile up forever)
# ─────────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 7
  tags              = var.tags
}

# ─────────────────────────────────────────────────────────────
# The Lambda function itself
# ─────────────────────────────────────────────────────────────
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda.arn
  handler          = var.handler
  runtime          = var.runtime
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = var.environment_variables
  }

  # Ensure log group exists before Lambda (so retention policy applies)
  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy_attachment.lambda,
  ]

  tags = var.tags
}