#########################
## Redshift IAM - Main ##
#########################

# Create an IAM Role for Redshift
resource "aws_iam_role" "redshift-role" {
  name = "${var.app_name}-${var.app_environment}-redshift-role"

assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "redshift.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name        = "${var.app_name}-${var.app_environment}-redshift-role"
    Environment = var.app_environment
  }
}

# Create and assign an IAM Role Policy to access S3 Buckets
resource "aws_iam_role_policy" "redshift-s3-full-access-policy" {
  name = "${var.app_name}-${var.app_environment}-redshift-role-s3-policy"
  role = aws_iam_role.redshift-role.id

policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Action": "s3:*",
       "Resource": "*"
      }
   ]
}
EOF
}

