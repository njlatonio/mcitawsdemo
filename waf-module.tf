module "waf" {
  source = "./waf/"

  web_acl_name = aws_wafv2_web_acl.example.name
  alb_arn = module.nlb.arn
}
