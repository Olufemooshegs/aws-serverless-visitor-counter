# terraform/environments/dev/outputs.tf

output "website_url" {
  description = "🌐 Open this in your browser"
  value       = "http://${module.s3_website.website_endpoint}"
}

output "api_url" {
  description = "API endpoint"
  value       = module.api_gateway.count_url
}

output "dynamodb_table" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "lambda_function" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}