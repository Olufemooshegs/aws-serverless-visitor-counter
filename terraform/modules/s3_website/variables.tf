variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "index_document" {
  description = "Default index document"
  type        = string
  default     = "index.html"
}

variable "source_dir" {
  description = "Directory containing the website files"
  type        = string
}

variable "api_url" {
  description = "API endpoint URL injected into the HTML"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}