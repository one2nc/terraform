variable "project_name" {
  type = string
}
variable "env" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "meta" {
  type = object({
    author = string
  })
}

locals {
  project_prefix = "${var.project_name}-${var.env}"
  default_route  = "0.0.0.0/0"
}

resource "null_resource" "tags" {
  triggers = {
    author = var.meta.author
  }
}

resource "null_resource" "public_subnet" {
  count = null_resource.azs.triggers.count
  triggers = {
      cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  }
}

resource "null_resource" "private_subnet" {
  count = null_resource.azs.triggers.count
  triggers = {
      cidr_block = cidrsubnet(var.vpc_cidr, 8, null_resource.azs.triggers.count+count.index)
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "${local.project_prefix}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = split(",", null_resource.az_names.triggers.list)
  private_subnets      = null_resource.private_subnet[*].triggers.cidr_block
  public_subnets       = null_resource.public_subnet[*].triggers.cidr_block
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${null_resource.eks_cluster.triggers.name}" = "shared",
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${null_resource.eks_cluster.triggers.name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${null_resource.eks_cluster.triggers.name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_security_group" "worker_group_mgmt" {
  name_prefix = "worker_group_mgmt"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_cidr,
    ]
  }
}