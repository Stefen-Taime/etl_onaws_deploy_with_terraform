resource "aws_glue_catalog_database" "example" {
  name = var.glue_database_name
}

resource "aws_iam_role" "glue_service_role" {
  name = var.glue_service_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


resource "aws_iam_role_policy" "glue_service_policy" {
  role   = aws_iam_role.glue_service_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "glue:GetDatabase",
        "glue:GetTables",
        "glue:CreateDatabase",
        "glue:CreateTable",
        "glue:DeleteTable",
        "glue:GetTable",
        "glue:GetTableVersion",
        "glue:GetTableVersions",
        "glue:UpdateTable",
        "glue:CreatePartition",
        "glue:BatchCreatePartition",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:BatchGetPartition",
        "glue:UpdatePartition",
        "glue:DeletePartition",
        "glue:BatchDeletePartition"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*",
        "arn:aws:glue:${var.region}:${var.account_id}:catalog",
        "arn:aws:glue:${var.region}:${var.account_id}:database/${var.glue_database_name}",
        "arn:aws:glue:${var.region}:${var.account_id}:table/${var.glue_database_name}/*"
        ]

    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "glue_logs_policy" {
  role   = aws_iam_role.glue_service_role.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws-glue/*"
    }
  ]
}
EOF
}

resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.example.name
  name          = var.glue_crawler_name
  role          = aws_iam_role.glue_service_role.arn

  s3_target {
    path = "s3://${var.s3_bucket_name}/AAPL"
    exclusions = ["scripts/*", "lambda2/*"]
  }

  s3_target {
    path = "s3://${var.s3_bucket_name}/IBM"
    exclusions = ["scripts/*", "lambda2/*"]
  }

  s3_target {
    path = "s3://${var.s3_bucket_name}/MSFT"
    exclusions = ["scripts/*", "lambda2/*"]
  }
}


variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "glue_crawler_name" {
  description = "The name of the Glue Crawler"
  type        = string
}

variable "glue_service_role_name" {
  description = "The name of the IAM role for the Glue service"
  type        = string
}

variable "glue_database_name" {
  description = "The name of the Glue database"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}
