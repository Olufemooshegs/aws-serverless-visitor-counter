# terraform/environments/dev/main.tf

# ─────────────────────────────────────────────────────────────
# 1. DynamoDB table
# ─────────────────────────────────────────────────────────────
module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name = "${var.project_name}-${var.environment}"
}

# ─────────────────────────────────────────────────────────────
# 2. Lambda function
#    - Gets the table ARN from module 1
#    - Env var TABLE_NAME injected so Python knows where to write
# ─────────────────────────────────────────────────────────────
module "lambda" {
  source = "../../modules/lambda"

  function_name = "${var.project_name}-${var.environment}"
  source_dir    = var.lambda_source_dir
  runtime       = "python3.12"
  handler       = "index.lambda_handler"

  environment_variables = {
    TABLE_NAME  = module.dynamodb.table_name
    COUNTER_KEY = "visitor_count"
  }

  dynamodb_table_arn = module.dynamodb.table_arn
}

# ─────────────────────────────────────────────────────────────
# 3. API Gateway
#    - Gets Lambda invoke ARN from module 2
# ─────────────────────────────────────────────────────────────
module "api_gateway" {
  source = "../../modules/api_gateway"

  api_name             = "${var.project_name}-${var.environment}-api"
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  route_key            = "GET /count"
}

# ─────────────────────────────────────────────────────────────
# 4. S3 website
#    - Bucket name must be globally unique → add account ID
#    - Inject the API URL into index.html
# ─────────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}

module "s3_website" {
  source = "../../modules/s3_website"

  bucket_name = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"
  source_dir  = var.frontend_source_dir
  api_url     = module.api_gateway.count_url
}