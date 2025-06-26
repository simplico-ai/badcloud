resource "aws_dynamodb_table" "insecure_table" {
  name           = "${var.project_name}-insecure-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-insecure-table"
    Environment = var.environment
  }
}