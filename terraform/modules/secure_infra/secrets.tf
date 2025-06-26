resource "aws_secretsmanager_secret" "app_secret" {
  name = "${var.project_name}-app-secret-v2"

  tags = {
    Name        = "${var.project_name}-app-secret"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id     = aws_secretsmanager_secret.app_secret.id
  secret_string = "my-super-secret-api-key"
}
