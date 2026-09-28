# terraform/environments/dev/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "visitor-counter"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "lambda_source_dir" {
  description = "Path to Lambda source directory (relative to this env dir)"
  type        = string
  default     = "../../../lambda/src"
}

variable "frontend_source_dir" {
  description = "Path to frontend source directory"
  type        = string
  default     = "../../../frontend"
}