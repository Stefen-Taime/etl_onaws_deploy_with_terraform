resource "aws_s3_bucket" "b" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}



variable "s3_bucket_name" {
  description = "Le nom du bucket S3"
  type        = string
}

output "s3_bucket_name" {
  description = "Le nom du bucket S3 créé"
  value       = aws_s3_bucket.b.id
}


