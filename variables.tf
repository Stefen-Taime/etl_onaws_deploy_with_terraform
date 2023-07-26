// Lambda_Function
variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "av-financial-analysis-bucket"
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
  default     = "data_extraction_lambda"
}

variable "lambda_function_name_2" {
  description = "The name of the second Lambda function"
  type        = string
  default     = "trigger_glue_workflow_lambda"  # or your desired default
}


variable "lambda_role_arn" {
  description = "The ARN of the IAM role for the Lambda function"
  type        = string
}


variable "lambda_role_name" {
  description = "The name of the IAM role for the Lambda function"
  type        = string
  default     = "lambda_role"
}

variable "lambda_role_name_2" {
  description = "The name of the IAM role for the second Lambda function"
  type        = string
  default     = "unique_lambda_role_name_2"  # Make sure this is unique
}

variable "lambda_source_code_file" {
  description = "The path to the source code file for the Lambda function"
  type        = string
  default     = "./lambda_functions/lambda1/deployment_package.zip"
}

variable "lambda_source_code_file_2" {
  description = "The path to the source code file for the second Lambda function"
  type        = string
  default     = "./lambda_functions/lambda2/lambda_function.zip"
}


// S3
variable "region" {
  description = "The AWS region to create resources in"
  type        = string
  default     = "us-east-1"  # Remplacez par la région de votre choix
}

// Crawler
variable "glue_database_name" {
  description = "The name of the Glue catalog database"
  type        = string
  default     = "av_financial_analysis"
}

variable "glue_service_role_name" {
  description = "The name of the IAM role for the Glue service"
  type        = string
  default     = "glue_service_role"
}

variable "glue_crawler_name" {
  description = "The name of the Glue crawler"
  type        = string
  default     = "av_financial_analysis_crawler"
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
  default     = ""  
}

// Glue Job
variable "glue_job_name" {
  description = "The name of the Glue job"
  type        = string
  default     = "av_financial_analysis_job"
}

variable "glue_job_script_name" {
  description = "The name of the Glue job script"
  default     = "scripts/glue_job_script.py"
}


