# ACM Module - To create and Verify SSL Certificates
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  #version = "2.14.0"
  #version = "3.0.0"
  version = "5.0.0"
  
  domain_name  = trimsuffix(data.aws_route53_zone.mydomain.name, ".")
  zone_id      = data.aws_route53_zone.mydomain.zone_id 

  subject_alternative_names = [
    "*.devopsincloud.com"
  ]
  #tags = local.common_tags
  
  # Validation Method
  validation_method = "DNS"
  wait_for_validation = true  
}

# Output ACM Certificate ARN
output "this_acm_certificate_arn" {
  description = "The ARN of the certificate"
  #value       = module.acm.this_acm_certificate_arn
  value       = module.acm.acm_certificate_arn
}

# AWS EC2 Security Group Terraform Module
# Security Group for Public Bastion Host
module "public_bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  #version = "4.0.0"
  version = "5.1.0"  

  name = "public-bastion-sg"
  description = "Security Group with SSH port open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  #tags = local.common_tags
}

# Security Group for Private EC2 Instances
module "private_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  #version = "4.0.0"
  version = "5.1.0"    
  
  name = "private-sg"
  description = "Security Group with HTTP & SSH port open for entire VPC Block (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["ssh-tcp", "http-80-tcp", "http-8080-tcp"]
  #ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  ingress_cidr_blocks = ["0.0.0.0/0"] # Required for NLB
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  #tags = local.common_tags
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
# Security Group for Public Load Balancer
module "loadbalancer_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  #version = "4.0.0"
  version = "5.1.0"  

  name = "loadbalancer-sg"
  description = "Security Group with HTTP open for entire Internet (IPv4 CIDR), egress ports are all world open"
  vpc_id = module.vpc.vpc_id
  # Ingress Rules & CIDR Blocks
  ingress_rules = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  #tags = local.common_tags

  # Open to CIDRs blocks (rule or from_port+to_port+protocol+description)
  ingress_with_cidr_blocks = [
    {
      from_port   = 81
      to_port     = 81
      protocol    = 6
      description = "Allow Port 81 from internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

# Create VPC Terraform Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  #version = "2.78.0"
  #version = "3.0.0"
  version = "5.4.0"

  # VPC Basic Details
  name = "${var.vpc_name}"
  cidr = var.vpc_cidr_block
  azs             = var.vpc_availability_zones
  public_subnets  = var.vpc_public_subnets
  private_subnets = var.vpc_private_subnets  

  # Database Subnets
  database_subnets = var.vpc_database_subnets
  create_database_subnet_group = var.vpc_create_database_subnet_group
  create_database_subnet_route_table = var.vpc_create_database_subnet_route_table
  # create_database_internet_gateway_route = true
  # create_database_nat_gateway_route = true
  
  # NAT Gateways - Outbound Communication
  enable_nat_gateway = var.vpc_enable_nat_gateway 
  single_nat_gateway = var.vpc_single_nat_gateway

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true


  #tags = local.common_tags
  #vpc_tags = local.common_tags

/*
  # Additional Tags to Subnets
  public_subnet_tags = {
    Type = "Public Subnets"
  }
  #private_subnet_tags = {
    Type = "Private Subnets"
  }  
  database_subnet_tags = {
    Type = "Private Database Subnets"
  }
*/
}

# Terraform AWS Network Load Balancer (NLB)
module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.4.0"

  name_prefix = "mynlb-"
  load_balancer_type               = "network"
  vpc_id                           = module.vpc.vpc_id
  dns_record_client_routing_policy = "availability_zone_affinity"
  security_groups = [module.loadbalancer_sg.security_group_id]

  # https://github.com/hashicorp/terraform-provider-aws/issues/17281
  subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

# Listeners
  listeners = {
    # Listener-1: TCP Listener
    my-tcp = {
      port     = 80
      protocol = "TCP"
      forward = {
        target_group_key = "mytg1"
      }
    }# End Listener-1: TCP Listener
    # Listener-2: TLS Listener (SSL)
    my-tls = {
      port            = 443
      protocol        = "TLS"
      certificate_arn = module.acm.acm_certificate_arn
      forward = {
        target_group_key = "mytg1"
      }
    }# End Listener-2: TLS Listener (SSL)
  }# End Listeners Block

# Target Groups
  target_groups = { 
    # Target Group-1: mytg1
    mytg1 = {
      create_attachment = false          
      name_prefix          = "mytg1-"
      protocol             = "TCP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/app1/index.html"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
      }# End Health Check Block
    }# End Target Group-1: mytg1
  }
 # tags = local.common_tags
}# End NLB Module

# To create a WAFv2 Web ACL resource
resource "aws_wafv2_web_acl" "example" {
  name        = "managed-rule-example"
  description = "Example of a managed rule."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_QUERYSTRING"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "NoUserAgent_HEADER"
        }

        scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "NL"]
          }
        }
      }
    }

    #token_domains = ["mywebsite.com", "myotherwebsite.com"]

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }

  tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}

# WAF association
resource "aws_wafv2_web_acl_association" "example" {
  resource_arn = module.nlb.arn
  web_acl_arn  = aws_wafv2_web_acl.example.arn
}
