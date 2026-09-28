output "api_id" {
  value = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Base URL of the API"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "count_url" {
  description = "Full URL to hit for the counter"
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/count"
}