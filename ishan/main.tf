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
  key_name = var.key_name
  public_key = var.public_key
}

module "app" {
  source = "./modules/app"

  vpc_id             = module.network.vpc_id
  private_subnet1_id  = module.network.private_subnet1_id
  private_subnet2_id = module.network.private_subnet2_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  aws_key_pair_id    = module.network.aws_key_pair_id
  rds_username       = var.rds_username
  rds_password       = var.rds_password
}

