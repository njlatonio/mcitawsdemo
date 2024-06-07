# VPC Output Values
# VPC ID
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# VPC CIDR blocks
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# VPC Private Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

# VPC Public Subnets
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# VPC NAT gateway Public IP
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

# VPC AZs
output "azs" {
  description = "A list of availability zones spefified as argument to this module"
  value       = module.vpc.azs
}

//////////////////////////////////////////////////////////////////////////////////////////////////
# AWS EC2 Security Group Terraform Outputs

# Public Bastion Host Security Group Outputs
## public_bastion_sg_group_id
output "public_bastion_sg_group_id" {
  description = "The ID of the security group"
  #value       = module.public_bastion_sg.this_security_group_id
  value       = module.public_bastion_sg.security_group_id
}

## public_bastion_sg_group_vpc_id
output "public_bastion_sg_group_vpc_id" {
  description = "The VPC ID"
  #value       = module.public_bastion_sg.this_security_group_vpc_id
  value       = module.public_bastion_sg.security_group_vpc_id
}

## public_bastion_sg_group_name
output "public_bastion_sg_group_name" {
  description = "The name of the security group"
  #value       = module.public_bastion_sg.this_security_group_name
  value       = module.public_bastion_sg.security_group_name
}

/*
# Private EC2 Instances Security Group Outputs
## private_sg_group_id
output "private_sg_group_id" {
  description = "The ID of the security group"
  #value       = module.private_sg.this_security_group_id
  value       = module.private_sg.security_group_id
}

## private_sg_group_vpc_id
output "private_sg_group_vpc_id" {
  description = "The VPC ID"
  #value       = module.private_sg.this_security_group_vpc_id    
  value       = module.private_sg.security_group_vpc_id
}

## private_sg_group_name
output "private_sg_group_name" {
  description = "The name of the security group"
  #value       = module.private_sg.this_security_group_name
  value       = module.private_sg.security_group_name
}
*/
