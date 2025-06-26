


# Secure DynamoDB Table
resource "aws_dynamodb_table" "secure_table" {
  name           = "${var.project_name}-secure-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn  = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-secure-table"
    Environment = var.environment
  }
}

# KMS Key for DynamoDB
resource "aws_kms_key" "dynamodb_key" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-dynamodb-key"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "dynamodb_key_alias" {
  name          = "alias/${var.project_name}-dynamodb-key"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

# Data sources
data "aws_region" "current" {}