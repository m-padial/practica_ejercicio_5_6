resource "aws_apprunner_service" "dash_app" {
  service_name = "volatilidad-dash-app"

  depends_on = [
    aws_lambda_function.scraping_lambda,
    aws_lambda_function.lambda_volatilidad,
    aws_dynamodb_table.scraping_data,
    aws_iam_role.apprunner_ecr_access,
    aws_iam_role_policy.apprunner_dash_policy
  ]

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_configuration {
        port = "8050"
      }
      image_identifier      = "${aws_ecr_repository.lambda_repository.repository_url}:dash"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = true
  }

  instance_configuration {
    cpu    = "1024"
    memory = "2048"
  }

  tags = {
    Name        = "Dash Volatilidad App"
    Environment = "dev"
  }
}


# --- IAM Role para App Runner (ECR + DynamoDB)
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "AppRunnerDashAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "tasks.apprunner.amazonaws.com"  # ✅ CORREGIDO
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# --- Permisos combinados para ECR + DynamoDB
resource "aws_iam_role_policy" "apprunner_dash_policy" {
  name = "AppRunnerDashPolicy"
  role = aws_iam_role.apprunner_ecr_access.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem"
        ],
        Resource = aws_dynamodb_table.scraping_data.arn
      },
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
