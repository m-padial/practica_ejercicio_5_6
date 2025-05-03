# --- Obtener ID de cuenta AWS (para interpolar en ARN de DynamoDB)
data "aws_caller_identity" "current" {}

# --- Rol IAM para App Runner con acceso a ECR y DynamoDB
resource "aws_iam_role" "apprunner_ecr_role" {
  name = "AppRunnerAutoCreatedRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "build.apprunner.amazonaws.com",
            "tasks.apprunner.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --- Adjuntar política oficial de ECR
resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# --- Política personalizada para DynamoDB
resource "aws_iam_role_policy" "apprunner_dynamodb_policy" {
  name = "AppRunnerDynamoDBAccess"
  role = aws_iam_role.apprunner_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable"
        ],
        Resource = "arn:aws:dynamodb:eu-west-1:${data.aws_caller_identity.current.account_id}:table/OpcionesFuturosMiniIBEX"
      }
    ]
  })
}

# --- Servicio App Runner con Deployment manual
resource "aws_apprunner_service" "dash_app" {
  service_name = "volatilidad-dash-app"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }

    image_repository {
      image_configuration {
        port = "8050"
      }
      image_identifier      = "${aws_ecr_repository.lambda_repository.repository_url}:dash"
      image_repository_type = "ECR"
    }

    auto_deployments_enabled = false # 🟠 Despliegue manual (como en consola)
  }

  instance_configuration {
    cpu                = "1024"
    memory             = "2048"
    instance_role_arn  = aws_iam_role.apprunner_ecr_role.arn # ✅ Útil si usas más servicios
  }

  tags = {
    Name        = "Dash Volatilidad App"
    Environment = "dev"
  }
}

