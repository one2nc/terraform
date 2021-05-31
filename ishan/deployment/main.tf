terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-east-1"
}

module "network" {
  source = "./modules/network"

  my_ip = var.my_ip
}

module "instances" {
  source = "./modules/instances"

  key_name                  = var.key_name
  public_key                = var.public_key
  vpc_id                    = module.network.vpc_id
  private_subnet1_id        = module.network.private_subnet1_id
  private_subnet2_id        = module.network.private_subnet2_id
  public_subnet1_id         = module.network.public_subnet1_id
  public_subnet2_id         = module.network.public_subnet2_id
  default_security_group_id = module.network.default_security_group_id
  private_security_group_id = module.network.private_security_group_id
}

module "load_balancers" {
  source = "./modules/load_balancers"

  vpc_id                  = module.network.vpc_id
  public_subnet1_id       = module.network.public_subnet1_id
  public_subnet2_id       = module.network.public_subnet2_id
  alb_default_sec_grp_id  = module.network.alb_default_sec_grp_id
  app_public_instance1_id = module.instances.app_public_instance1_id
  app_public_instance2_id = module.instances.app_public_instance2_id
}

module "rds" {
  source = "./modules/rds"

  vpc_id                = module.network.vpc_id
  private_subnet1_id    = module.network.private_subnet1_id
  private_subnet2_id    = module.network.private_subnet2_id
  rds_username          = var.rds_username
  rds_password          = var.rds_password
  rds_security_group_id = module.network.rds_security_group_id
}

