variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda invoke ARN"
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name (for permission)"
  type        = string
}

variable "route_key" {
  description = "Route key, e.g. GET /count"
  type        = string
  default     = "GET /count"
}

variable "tags" {
  type    = map(string)
  default = {}
}