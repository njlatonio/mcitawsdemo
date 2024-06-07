# Input Variables
# AWS Region
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
  default = "us-east-1"  
}

# Access keys
variable "AWS_ACCESS_KEY"{
}
variable "AWS_SECRET_ACCESS_KEY"{ 
}
