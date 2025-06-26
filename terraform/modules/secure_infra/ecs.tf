# ECS Cluster
resource "aws_ecs_cluster" "secure" {
  name = "${var.project_name}-secure-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-secure-cluster"
    Environment = var.environment
  }
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-ecs-tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-tasks-sg"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "secure_app" {
  family             = "${var.project_name}-secure-app"
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                = "256"
  memory             = "512"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "secure-app"
      image = "${aws_ecr_repository.app_repository.repository_url}:latest"

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "nginx-cache",
          containerPath = "/var/cache/nginx"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      readonlyRootFilesystem = true

      secrets = [
        {
          name      = "API_KEY"
          valueFrom = aws_secretsmanager_secret.app_secret.arn
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
    }
  ])

  volume {
    name = "nginx-cache"
  }

  tags = {
    Name        = "${var.project_name}-secure-app"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "secure_app" {
  name            = "${var.project_name}-secure-app"
  cluster         = aws_ecs_cluster.secure.id
  task_definition = aws_ecs_task_definition.secure_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name        = "${var.project_name}-secure-app"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}-secure"
  retention_in_days = 3

  tags = {
    Name        = "${var.project_name}-ecs-logs"
    Environment = var.environment
  }
}

# IAM Role for ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

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
    Name        = "${var.project_name}-ecs-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

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
    Name        = "${var.project_name}-ecs-task-role"
    Environment = var.environment
  }
}

# IAM Policy for DynamoDB Access
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.project_name}-dynamodb-access-policy"
  description = "Policy to allow access to the secure DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.secure_table.arn
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.dynamodb_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_dynamodb_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}


resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.project_name}-secrets-manager-access-ecs-execution-role-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.app_secret.arn,
      ]
    }]
  })
}
