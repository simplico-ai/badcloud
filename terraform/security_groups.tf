resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc_endpoint_sg"
  description = "Allow HTTP inbound traffic from internal sources"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg"
    Environment = var.env
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecr-dkr-endpoint"
    Environment = var.env
  }
}