# terraform/bootstrap/main.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Random suffix so bucket name is globally unique
resource "random_id" "suffix" {
  byte_length = 4
}

# ─────────────────────────────────────────────────────────────
# S3 bucket: stores terraform.tfstate for all environments
# ─────────────────────────────────────────────────────────────
resource "aws_s3_bucket" "tf_state" {
  bucket = "visitor-counter-tfstate-${random_id.suffix.hex}"

  # Prevents accidental deletion via `terraform destroy`
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# Enable versioning — lets you roll back to previous state files
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access — state files contain secrets!
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─────────────────────────────────────────────────────────────
# DynamoDB table: state locking (prevents concurrent applies)
# ─────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "tf_lock" {
  name         = "visitor-counter-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}