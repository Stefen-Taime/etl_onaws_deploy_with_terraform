output "s3_bucket_name" {
  description = "Le nom du bucket S3 créé"
  value       = module.s3.s3_bucket_name
}

output "lambda1_function_name" {
  description = "Le nom de la première fonction Lambda créée"
  value       = module.lambda1.lambda_function_name
}

