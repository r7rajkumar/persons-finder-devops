output "ecr_repository_url" {
  value = aws_ecr_repository.persons_finder.repository_url
}

output "openai_secret_arn" {
  value = aws_secretsmanager_secret.openai_api_key.arn
}
