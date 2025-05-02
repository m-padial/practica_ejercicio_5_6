resource "aws_apprunner_service" "dash_app" {
  service_name = "volatilidad-dash-app"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_configuration {
        port = "8050" # Puerto por defecto de Dash
      }
      image_identifier      = "${aws_ecr_repository.lambda_repository.repository_url}:dash"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = "1024"  # 1 vCPU
    memory = "2048"  # 2 GB RAM
  }

  tags = {
    Name        = "Dash Volatilidad App"
    Environment = "dev"
  }
}

resource "aws_iam_role" "apprunner_ecr_access" {
  name = "AppRunnerDashAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apprunner_ecr_policy" {
  name = "AppRunnerECRPolicy"
  role = aws_iam_role.apprunner_ecr_access.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource = aws_ecr_repository.lambda_repository.arn
      },
      {
        Effect = "Allow",
        Action = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      }
    ]
  })
}
