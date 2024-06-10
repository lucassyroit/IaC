resource "aws_ecr_repository" "ecr" {
  name = "ecr"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ECR Repository"
  }
}
