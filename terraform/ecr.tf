resource "aws_ecr_repository" "persons_finder" {
  name                 = var.app_name
  image_tag_mutability = "IMMUTABLE" # tags can't be overwritten once pushed

  image_scanning_configuration {
    scan_on_push = true # ECR's own basic scan-on-push, in addition to Trivy in CI
  }

  tags = {
    Application = var.app_name
    ManagedBy   = "terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "expire_untagged" {
  repository = aws_ecr_repository.persons_finder.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images after 14 days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 14
      }
      action = { type = "expire" }
    }]
  })
}
