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

output "subnet_b" {
    value = data.aws_subnets.default.ids[0]
  }

output "subnet_a" {
    value = data.aws_subnets.default.ids[1]
  }

output "subnet_c" {
    value = data.aws_subnets.default.ids[2]
  }

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
  
}