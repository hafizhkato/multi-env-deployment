output "s3_bucket_name" {
  value = aws_s3_bucket.frontend_bucket.id
}

# output "ec2_instance_id" {
#   value = aws_instance.backend_instance.id
# }

output "ecr_repo_url" {
  value = aws_ecr_repository.backend_repo.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.app_cluster.name
}