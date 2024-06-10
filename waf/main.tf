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
