module "vpc" {
  count = var.vpc_id == null ? 1 : 0
  
  source = "terraform-aws-modules/vpc/aws"

  name               = local.name
  cidr               = "10.0.0.0/16"
  azs                = var.availability_zones
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  tags               = local.default_tags
}
