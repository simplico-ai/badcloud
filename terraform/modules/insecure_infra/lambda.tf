# 1. Zip up the Lambda function code
resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# 2. IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-insecure-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-insecure-lambda-exec-role"
    Environment = var.environment
  }
}

# 3. IAM Policy Attachment for VPC Access
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# 4. Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  name_prefix = "${var.project_name}-insecure-lambda-sg"
  description = "Security group for the insecure Lambda function"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-insecure-lambda-sg"
    Environment = var.environment
  }
}

resource aws_vpc_security_group_ingress_rule "insecure_lambda_ingress_rule" {
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_ipv4  = "0.0.0.0/0"
}

# 5. Lambda Function
resource "aws_lambda_function" "insecure_lambda" {
  function_name = "${var.project_name}-insecure-lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = archive_file.lambda_zip.output_path
  source_code_hash = archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.public_subnets
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = {
    Name        = "${var.project_name}-insecure-lambda"
    Environment = var.environment
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc_access,
    archive_file.lambda_zip
  ]
}