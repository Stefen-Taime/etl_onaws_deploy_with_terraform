variable "lambda_function_name" {
  description = "Le nom de la fonction Lambda"
  type        = string
}

variable "s3_bucket_name" {
  description = "Le nom du bucket S3"
  type        = string
}

variable "lambda_role_name" {
  description = "Le nom du rôle IAM pour la fonction Lambda"
  type        = string
}

resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_s3" {
  name   = "lambda_s3"
  role   = aws_iam_role.lambda_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${var.s3_bucket_name}/*"
    }
  ]
}
EOF
}

variable "lambda_source_code_file" {
  description = "The path to the source code file for the Lambda function"
  type        = string
  default     = "deployment_package.zip"
}

resource "aws_lambda_function" "data_extraction_lambda" {
  function_name    = var.lambda_function_name
  filename         = var.lambda_source_code_file
  source_code_hash = filebase64sha256(var.lambda_source_code_file)
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 300

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
    }
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_extraction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

output "lambda_function_name" {
  description = "Le nom de la première fonction Lambda créée"
  value       = aws_lambda_function.data_extraction_lambda.function_name
}
