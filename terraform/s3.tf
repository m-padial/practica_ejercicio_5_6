resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "scraping-lambda-bucket-auto"  # MISMO NOMBRE que en el YAML
  force_destroy = true

  tags = {
    Name        = "LambdaCodeBucket"
    Environment = "dev"
  }
}
