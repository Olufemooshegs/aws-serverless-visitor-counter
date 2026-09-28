output "bucket_name" {
  value = aws_s3_bucket.this.id
}

output "website_endpoint" {
  description = "S3 static website URL"
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}