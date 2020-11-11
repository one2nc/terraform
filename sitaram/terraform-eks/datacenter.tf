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
  default_route = "0.0.0.0/0"
}

resource "null_resource" "tags" {
    triggers = {
        author = var.meta.author
    }
}

resource "aws_vpc" "eks_vpc" {
    cidr_block = var.vpc_cidr
    tags = merge(null_resource.tags.triggers, map("Name", "${local.project_prefix}-vpc"))
}

# EKS specific Tags addes as per documentation at
# https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
resource "aws_subnet" "public" {
    count = null_resource.azs.triggers.count
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available_zones.names[count.index]
    tags = merge(null_resource.tags.triggers, {"kubernetes.io/role/elb": "1", "kubernetes.io/cluster/${null_resource.eks_cluster.triggers.name}": "shared", "Name": "${local.project_prefix}-public"})
}

resource "aws_subnet" "private" {
    count = null_resource.azs.triggers.count
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, null_resource.azs.triggers.count+count.index)
    map_public_ip_on_launch = false
    availability_zone = data.aws_availability_zones.available_zones.names[count.index]
    tags = merge(null_resource.tags.triggers, {"kubernetes.io/role/internal-elb": "1", "kubernetes.io/cluster/${null_resource.eks_cluster.triggers.name}": "shared", "Name": "${local.project_prefix}-public"})
}

resource "aws_security_group" "public_sg" {
  name   = "${local.project_prefix}-public-sg"
  vpc_id = aws_vpc.eks_vpc.id
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
  vpc_id = aws_vpc.eks_vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.public[*].cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.default_route]
  }
}

resource "aws_internet_gateway" "eks_vpc_ig" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = merge(null_resource.tags.triggers, map("Name", "${local.project_prefix}-ig"))
}

resource "aws_eip" "nat" {
  count = null_resource.azs.triggers.count
  vpc   = true
}

resource "aws_nat_gateway" "nat" {
  count         = null_resource.azs.triggers.count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags       = null_resource.tags.triggers
  depends_on = [aws_internet_gateway.eks_vpc_ig]
}

resource "aws_route_table" "public_subnet_rt" {
  count = null_resource.azs.triggers.count
  depends_on = [
    aws_vpc.eks_vpc,
    aws_internet_gateway.eks_vpc_ig
  ]
  vpc_id = aws_vpc.eks_vpc.id
  tags   = merge(null_resource.tags.triggers, map("name", "${local.project_prefix}-public-rt"))
}

resource "aws_route_table" "private_subnet_rt" {
  count = null_resource.azs.triggers.count
  depends_on = [
    aws_vpc.eks_vpc,
    aws_internet_gateway.eks_vpc_ig
  ]
  vpc_id = aws_vpc.eks_vpc.id
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
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_subnet_rt[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = null_resource.azs.triggers.count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_subnet_rt[count.index].id
}
