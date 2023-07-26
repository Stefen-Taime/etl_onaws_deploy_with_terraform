# Configure the AWS Provider
provider "aws" {
  region = var.region
  # Si vous avez configuré vos clés d'accès avec `aws configure`,
  # vous n'avez pas besoin de spécifier `access_key` et `secret_key` ici.
}



############################################### Module 1  #################################################

# Appeler le module pour le bucket S3
module "s3" {
  source = "./s3"
  s3_bucket_name = var.s3_bucket_name
}

# Appeler le module pour la première fonction Lambda
module "lambda1" {
  source = "./lambda_functions/lambda1"
  s3_bucket_name = var.s3_bucket_name
  lambda_function_name = var.lambda_function_name
  lambda_role_name = var.lambda_role_name
  lambda_source_code_file = var.lambda_source_code_file
}


############################################### Module 2  #################################################


# Appeler le module pour le crawler Glue
module "glue_crawler" {
  source = "./glue/crawler"
  s3_bucket_name = var.s3_bucket_name
  glue_crawler_name = var.glue_crawler_name
  glue_service_role_name = var.glue_service_role_name
  glue_database_name = var.glue_database_name
  region = var.region
  account_id = var.account_id
}


# Appeler le module pour le job Glue
module "glue_job" {
  source = "./glue/job"
  s3_bucket_name = var.s3_bucket_name
  glue_job_name = var.glue_job_name
  glue_service_role_name = var.glue_service_role_name
  glue_job_script_name = var.glue_job_script_name
  glue_database_name = var.glue_database_name
  account_id = var.account_id  # Ajoutez cette ligne

  
}

############################################### Module 3  #################################################


# Appeler le module pour la deuxième fonction Lambda
module "lambda2" {
  source = "./lambda_functions/lambda2"
  s3_bucket_name = var.s3_bucket_name
  lambda_function_name_2 = var.lambda_function_name_2
  lambda_role_name = var.lambda_role_name_2  # Use the new variable here
  glue_crawler_name = var.glue_crawler_name
  lambda_source_code_file_2 = "lambda2/lambda_function.zip"  # Make sure this points to your actual Lambda function code in S3
  glue_job_name = var.glue_job_name
}















