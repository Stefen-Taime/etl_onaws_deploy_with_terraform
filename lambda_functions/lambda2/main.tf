variable "s3_bucket_name" {
  description = "Le nom du bucket S3"
  type        = string
}

variable "lambda_function_name_2" {
  description = "Le nom de la deuxième fonction Lambda"
  type        = string
}

variable "glue_crawler_name" {
  description = "Le nom du crawler Glue"
  type        = string
}

variable "glue_job_name" {
  description = "Le nom du job Glue"
  type        = string
}

variable "lambda_role_name" {
  description = "Le nom du rôle IAM pour la fonction Lambda"
  type        = string
  default     = "lambda_glue_s3_role_2"  # Modifiez ceci à un nom unique
}



variable "lambda_source_code_file_2" {
  description = "The path to the source code file for the second Lambda function"
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

resource "aws_iam_role_policy" "lambda_glue_s3_access" {
  name = "lambda_glue_s3_access"
  role = aws_iam_role.lambda_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "glue:StartJobRun",
        "glue:GetJobRun",
        "glue:GetJobRuns",
        "glue:BatchStopJobRun",
        "glue:StartCrawler",
        "glue:GetCrawler",
        "glue:GetCrawlerMetrics",
        "glue:GetCrawlers",
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_lambda_function" "trigger_glue_workflow" {
  function_name = var.lambda_function_name_2  
  role = aws_iam_role.lambda_role.arn
  handler = "lambda_function.lambda_handler"

  s3_bucket = var.s3_bucket_name
  s3_key    = "${var.lambda_source_code_file_2}"
  timeout          = 300

  runtime = "python3.8"

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
      GLUE_CRAWLER_NAME = var.glue_crawler_name
      GLUE_JOB_NAME = var.glue_job_name
    }
  }
}