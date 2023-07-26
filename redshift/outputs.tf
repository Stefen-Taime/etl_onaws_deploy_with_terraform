#######################
## Network - Outputs ##
#######################

output "redshift_vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.redshift-vpc.id
}

output "redshift_vpc_cidr" {
  description = "The CIDR of the VPC"
  value       = var.redshift_vpc_cidr
}

output "redshift_subnet_az1_id" {
  description = "Redshift Subnet AZ1"
  value       = aws_subnet.redshift-subnet-az1.id
}

output "redshift_subnet_az1_cidr" {
  description = "Redshift Subnet AZ1 CIDR"
  value       = var.redshift_subnet_1_cidr
}

output "redshift_subnet_az2_id" {
  description = "Redshift Subnet AZ2"
  value       = aws_subnet.redshift-subnet-az2.id
}

output "redshift_subnet_az2_cidr" {
  description = "Redshift Subnet AZ2 CIDR"
  value       = var.redshift_subnet_2_cidr
}

###########################
## Redshift IAM - Output ##
###########################

output "redshift_iam_role_arn" {
  description = "Redshift IAM Role"
  value       = aws_iam_role.redshift-role.arn
}

#############################
## Security Group - Output ##
#############################

output "redshift_security_group_id" {
  description = "Redshift Security Group"
  value       = aws_default_security_group.redshift_security_group.id
}

###############################
## Redshift Cluster - Output ##
###############################

output "redshift_cluster_id" {
  description = "Redshift Cluster ID"
  value       = aws_redshift_cluster.redshift-cluster.id
}

output "redshift_cluster_dns_name" {
  description = "Redshift Cluster DNS Name"
  value       = aws_redshift_cluster.redshift-cluster.dns_name
}
