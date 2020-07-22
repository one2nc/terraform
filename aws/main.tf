provider "aws" {
  profile = "aws-homie"
  region  = "ap-south-1"
}

module "vpc" {
  source        = "./vpc"
  vpc_cidr      = "10.0.0.0/16"
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

}

module "ec2" {
  source         = "./ec2"
  my_public_key  = "/home/siddharthshashikar/work/aws-fun/keys/aws_key_pub.pem"
  instance_type  = "t2.micro"
  security_group = "${module.vpc.security_group}"
  subnets        = "${module.vpc.public_subnets}"
}
