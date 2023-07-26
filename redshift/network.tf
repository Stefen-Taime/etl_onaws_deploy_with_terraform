####################
## Network - Main ##
####################

# AWS Availability Zones data
data "aws_availability_zones" "available" {}

######################################

# Create the VPC
resource "aws_vpc" "redshift-vpc" {
  cidr_block           = var.redshift_vpc_cidr
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-redshift-vpc"
    Environment = var.app_environment
  }
}

######################################

# Create the Redshift Subnet AZ1
resource "aws_subnet" "redshift-subnet-az1" {
  vpc_id            = aws_vpc.redshift-vpc.id
  cidr_block        = var.redshift_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-redshift-subnet-az1"
    Environment = var.app_environment
  }
}

# Create the Redshift Subnet AZ2
resource "aws_subnet" "redshift-subnet-az2" {
  vpc_id            = aws_vpc.redshift-vpc.id
  cidr_block        = var.redshift_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name        = "${var.app_name}-${var.app_environment}-redshift-subnet-az2"
    Environment = var.app_environment
  }
}

######################################

# Create the Redshift Subnet Group
resource "aws_redshift_subnet_group" "redshift-subnet-group" {
  depends_on = [
    aws_subnet.redshift-subnet-az1,
    aws_subnet.redshift-subnet-az2,
  ]

  name       = "${var.app_name}-${var.app_environment}-redshift-subnet-group"
  subnet_ids = [aws_subnet.redshift-subnet-az1.id, aws_subnet.redshift-subnet-az2.id]

  tags = {
    Name        = "${var.app_name}-${var.app_environment}-redshift-subnet-group"
    Environment = var.app_environment
  }
}

######################################

# Internet Gateway
resource "aws_internet_gateway" "redshift-igw" {
  vpc_id = aws_vpc.redshift-vpc.id

  tags = {
    Name        = "${var.app_name}-${var.app_environment}-redshift-igw"
    Environment = var.app_environment
  }
}

# Define the redshift route table to Internet Gateway
resource "aws_route_table" "redshift-rt-igw" {
  vpc_id = aws_vpc.redshift-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.redshift-igw.id
  }

  tags = {
    Name        = "${var.app_name}-${var.app_environment}-redshift-public-route-igw"
    Environment = var.app_environment
  }
}

# Assign the redshift route table to the redshift Subnet az1 for IGW 
resource "aws_route_table_association" "redshift-subnet-rt-association-igw-az1" {
  subnet_id      = aws_subnet.redshift-subnet-az1.id
  route_table_id = aws_route_table.redshift-rt-igw.id
}

# Assign the public route table to the redshift Subnet az2 for IGW 
resource "aws_route_table_association" "redshift-subnet-rt-association-igw-az2" {
  subnet_id      = aws_subnet.redshift-subnet-az2.id
  route_table_id = aws_route_table.redshift-rt-igw.id
}

######################################

