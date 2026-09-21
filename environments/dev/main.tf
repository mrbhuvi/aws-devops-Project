module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = var.vpc_cidr

  public_subnet_1_cidr = var.public_subnet_1_cidr
  public_subnet_2_cidr = var.public_subnet_2_cidr

  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr

  availability_zone_1 = var.availability_zone_1
  availability_zone_2 = var.availability_zone_2
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  environment  = var.environment

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

module "asg" {
  source = "../../modules/asg"

  project_name = var.project_name
  environment  = var.environment

  private_subnet_ids = module.vpc.private_subnet_ids

  ec2_security_group_id = module.security.ec2_security_group_id

  target_group_arn = module.alb.target_group_arn

  instance_type    = var.instance_type
  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size
}