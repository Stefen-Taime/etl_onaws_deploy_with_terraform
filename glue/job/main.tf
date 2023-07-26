# Commentez ou supprimez ces ressources si le rôle existe déjà
#resource "aws_iam_role" "glue_service_role" {
#  name = var.glue_service_role_name
#  assume_role_policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": "sts:AssumeRole",
#      "Principal": {
#        "Service": "glue.amazonaws.com"
#      },
#      "Effect": "Allow",
#      "Sid": ""
#    }
#  ]
#}
#EOF
#}

#resource "aws_iam_role_policy_attachment" "glue_policy_attach" {
#  role       = aws_iam_role.glue_service_role.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
#}

resource "aws_iam_policy" "s3_access" {
  name        = "S3Access"
  description = "Policy for accessing specific S3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_access_attach" {
  role       = var.glue_service_role_name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_glue_job" "example" {
  name     = var.glue_job_name
  role_arn = "arn:aws:iam::${var.account_id}:role/${var.glue_service_role_name}"

  glue_version = "3.0"

 command {
    script_location = "s3://${var.s3_bucket_name}/${var.glue_job_script_name}"
    python_version  = "3"
}


  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--TempDir" = "s3://${var.s3_bucket_name}"
    "--job-language" = "python"
  }

  depends_on = [aws_s3_bucket_object.example]
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

resource "aws_s3_bucket_object" "example" {
  bucket = var.s3_bucket_name  
  key    = "scripts/glue_job_script.py" 
  source = "${path.module}/glue_job.py"
  acl    = "private"
}

variable "glue_job_name" {
  description = "The name of the Glue job"
  type        = string
}

variable "glue_service_role_name" {
  description = "The name of the IAM role for the Glue service"
  type        = string
}

variable "glue_job_script_name" {
  description = "The name of the Glue job script"
  default     = "scripts/glue_job_script.py"
}


variable "glue_database_name" {
  description = "The name of the Glue catalog database"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}
