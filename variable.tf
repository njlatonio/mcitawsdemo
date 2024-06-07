# Input Variables
# AWS Region
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
}

# Access keys
variable "AWS_ACCESS_KEY"{
}
variable "AWS_SECRET_ACCESS_KEY"{ 
}

# AWS EC2 Instance Terraform Variables
# EC2 Instance Variables
# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 Instance Type"
  type = string 
}
# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
}
