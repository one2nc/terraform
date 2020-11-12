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


resource "aws_security_group" "public_sg" {
  name   = "${local.project_prefix}-public-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.default_route]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.default_route]
  }
}

resource "aws_security_group" "private_sg" {
  name   = "${local.project_prefix}-private-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = null_resource.public_subnet[*].triggers.cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.default_route]
  }
}

resource "aws_internet_gateway" "eks_vpc_ig" {
  vpc_id = module.vpc.vpc_id

  tags = merge(null_resource.tags.triggers, map("Name", "${local.project_prefix}-ig"))
}

resource "aws_eip" "nat" {
  count = null_resource.azs.triggers.count
  vpc   = true
}

resource "aws_nat_gateway" "nat" {
  count         = null_resource.azs.triggers.count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = null_resource.public_subnet[count.index].id

  tags       = null_resource.tags.triggers
  depends_on = [aws_internet_gateway.eks_vpc_ig]
}

resource "aws_route_table" "public_subnet_rt" {
  count = null_resource.azs.triggers.count
  depends_on = [
    module.vpc,
    aws_internet_gateway.eks_vpc_ig
  ]
  vpc_id = module.vpc.vpc_id
  tags   = merge(null_resource.tags.triggers, map("name", "${local.project_prefix}-public-rt"))
}

resource "aws_route_table" "private_subnet_rt" {
  count = null_resource.azs.triggers.count
  depends_on = [
    module.vpc,
    aws_internet_gateway.eks_vpc_ig
  ]
  vpc_id = module.vpc.vpc_id
  tags   = merge(null_resource.tags.triggers, map("name", "${local.project_prefix}-private-rt"))
}

resource "aws_route" "public" {
  count                  = null_resource.azs.triggers.count
  route_table_id         = aws_route_table.public_subnet_rt[count.index].id
  destination_cidr_block = local.default_route
  gateway_id             = aws_internet_gateway.eks_vpc_ig.id
}
resource "aws_route" "private" {
  count                  = null_resource.azs.triggers.count
  route_table_id         = aws_route_table.private_subnet_rt[count.index].id
  destination_cidr_block = local.default_route
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "public" {
  count          = null_resource.azs.triggers.count
  subnet_id      = null_resource.private_subnet[count.index].id
  route_table_id = aws_route_table.public_subnet_rt[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = null_resource.azs.triggers.count
  subnet_id      = null_resource.private_subnet[count.index].id
  route_table_id = aws_route_table.private_subnet_rt[count.index].id
}
