module "waf" {
  source = "./waf/"

  web_acl_name = var.web_acl_name
}
