# modules/secure/outputs.tf
output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.secure.id
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.secure_table.name
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repository.repository_url
}