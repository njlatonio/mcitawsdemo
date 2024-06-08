module "waf" {
  source = "./"

  name = aws_wafv2_web_acl.example.name
  alb_arn = module.nlb.arn
}
