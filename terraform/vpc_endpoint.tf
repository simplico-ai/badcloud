resource "aws_vpc_endpoint" "vpc_endpoint_dynamodb" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat([aws_route_table.public_route_table.id], aws_route_table.private_route_table[*].id)
  tags = {
    Name        = "${var.project_name}-dynamodb-endpoint"
    Environment = var.env
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = concat([aws_route_table.public_route_table.id], aws_route_table.private_route_table[*].id)

  tags = {
    Name        = "${var.project_name}-s3-endpoint"
    Environment = var.env
  }
}

resource "aws_vpc_endpoint" "secrets_manager_endpoint" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "secretsmanager:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecr-api-endpoint"
    Environment = var.env
  }
}