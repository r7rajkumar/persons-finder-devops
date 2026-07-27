output "ecr_repository_url" {
  value       = aws_ecr_repository.persons_finder.repository_url
  description = "ECR repository URL — use this to tag and push images"
}

output "ecr_push_commands" {
  value       = <<-EOT
    # Authenticate Docker to ECR
    aws ecr get-login-password --region ${var.aws_region} | \
      docker login --username AWS --password-stdin ${aws_ecr_repository.persons_finder.repository_url}

    # Build, tag, and push
    docker build -t ${aws_ecr_repository.persons_finder.repository_url}:latest .
    docker push ${aws_ecr_repository.persons_finder.repository_url}:latest
  EOT
  description = "Commands to push Docker image to ECR"
}

output "openai_secret_arn" {
  value       = aws_secretsmanager_secret.openai_api_key.arn
  description = "ARN of the Secrets Manager secret for OPENAI_API_KEY"
}

output "kubectl_config_command" {
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.app_name}-cluster"
  description = "Run this after terraform apply to configure kubectl"
}
