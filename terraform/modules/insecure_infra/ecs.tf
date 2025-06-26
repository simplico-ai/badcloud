locals {
  insecure_sg_ingress_rules = {
    all_tcp = {
      description = "Allow all inbound TCP traffic from anywhere"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  insecure_sg_egress_rules = {
    all_traffic = {
      description = "Allow all outbound traffic to anywhere"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_ecs_cluster" "insecure" {
  name = "${var.project_name}-insecure-cluster"

  tags = {
    Name        = "${var.project_name}-insecure-cluster"
    Environment = var.environment
  }
}

resource "aws_security_group" "insecure_ecs_sg" {
  name_prefix = "${var.project_name}-insecure-ecs"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.insecure_sg_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.insecure_sg_egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name        = "${var.project_name}-insecure-ecs-sg"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "insecure_app" {
  family             = "${var.project_name}-insecure-app"
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                = "256"
  memory             = "512"
  execution_role_arn = aws_iam_role.insecure_execution_role.arn
  task_role_arn      = aws_iam_role.insecure_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "insecure-app"
      image = "${aws_ecr_repository.app_repository.repository_url}:latest"

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        { "name" : "NODE_ENV", "value" : "development" },
        { "name" : "DB_PASSWORD", "value" : "admin123" }
      ]
    }
  ])

  tags = {
    Name        = "${var.project_name}-insecure-app"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "insecure_app" {
  name            = "${var.project_name}-insecure-app"
  cluster         = aws_ecs_cluster.insecure.id
  task_definition = aws_ecs_task_definition.insecure_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.public_subnets  # INSECURE: Using public subnets
    security_groups = [aws_security_group.insecure_ecs_sg.id]
    assign_public_ip = true  # INSECURE: Assigning public IP
  }

  tags = {
    Name        = "${var.project_name}-insecure-app"
    Environment = var.environment
  }
}

resource "aws_iam_role" "insecure_execution_role" {
  name = "${var.project_name}-insecure-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-insecure-execution-role"
    Environment = var.environment
  }
}

# INSECURE: Attaching admin policy
resource "aws_iam_role_policy_attachment" "insecure_admin_policy" {
  role       = aws_iam_role.insecure_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"  # INSECURE: Too broad permissions
}

resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.project_name}-insecure-dynamodb-access-policy"
  description = "Policy to allow access to the secure DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:*Item",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:dynamodb:*:*:table/*",
          "arn:aws:dynamodb:*:*:table/*/index/*",
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_role_dynamodb_access" {
  role       = aws_iam_role.insecure_execution_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}
resource "aws_iam_role" "insecure_ecs_task_role" {
  name = "${var.project_name}-insecure-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-insecure-ecs-task-role"
    Environment = var.environment
  }
}
