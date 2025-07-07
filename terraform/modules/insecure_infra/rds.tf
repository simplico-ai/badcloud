resource "aws_db_subnet_group" "subnet_group_rds" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnets
}

resource "aws_security_group" "security_group_rds" {
  name_prefix = "${var.project_name}-insecure-lambda-rds"
  description = "Security group for the insecure RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-insecure-lambda-rds"
    Environment = var.environment
  }
}


resource "aws_rds_cluster" "postgres_cluster" {
  engine                 = "aurora-postgresql"
  engine_version         = "15.2"
  master_username        = "postgres"
  master_password        = "admin123"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.security_group_rds.id]
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.subnet_group_rds.name
  storage_encrypted      = false
  tags = {
    Name        = "${var.project_name}-insecure-postgres-cluster"
    Environment = var.environment
  }
}



resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "${var.project_name}-insecure-postgres-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.postgres_cluster.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.postgres_cluster.engine
  engine_version     = aws_rds_cluster.postgres_cluster.engine_version
  db_subnet_group_name = aws_rds_cluster.postgres_cluster.db_subnet_group_name
  tags = {
    Name        = "${var.project_name}-insecure-postgres-instance"
    Environment = var.environment
  }
}