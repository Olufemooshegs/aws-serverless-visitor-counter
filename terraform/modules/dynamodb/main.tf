resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Point-in-time recovery — free-ish insurance against accidental deletes
  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}