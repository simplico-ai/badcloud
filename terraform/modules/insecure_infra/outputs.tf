# modules/insecure/outputs.tf
output "insecure_cluster_id" {
  description = "Insecure ECS Cluster ID"
  value       = aws_ecs_cluster.insecure.id
}

output "insecure_table_name" {
  description = "Insecure DynamoDB table name"
  value       = aws_dynamodb_table.insecure_table.name
}
