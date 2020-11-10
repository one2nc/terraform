output "bastion_private_key" {
  value = tls_private_key.bastion.private_key_pem
}

output "webserver_private_key" {
  value = tls_private_key.webserver.private_key_pem
}

output "bastian_public_ip" {
  value = aws_instance.bastion.*.public_ip
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
    type = string
    default = "10.1.0.0/16"
}

variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "meta" {
  type = object({
    author = string
  })
}

variable "bastion" {
  type = object({
    count = number
    ami = string
    type = string
  })
}

locals {
  project_prefix = "${var.project_name}-${var.env}"
  default_route = "0.0.0.0/0"
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
}

resource "aws_key_pair" "bastion" {
  key_name   = "${local.project_prefix}-bastion"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "tls_private_key" "webserver" {
  algorithm = "RSA"
}

resource "aws_key_pair" "webserver" {
  key_name   = "${local.project_prefix}-webserver"
  public_key = tls_private_key.webserver.public_key_openssh
}

resource "null_resource" "tags" {
  triggers = {
    author = var.meta.author
    project_name = var.project_name
  }
}

provider "aws" {
    region = var.region
}

resource "aws_vpc" "main_vpc" {
    cidr_block = var.vpc_cidr
    tags = null_resource.tags.triggers
}

resource "aws_subnet" "public" {
    count = null_resource.az_count.triggers.total
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_public_ip_on_launch = true
    availability_zone = lookup(null_resource.az_names, count.index)

    tags = null_resource.tags.triggers
}

resource "aws_subnet" "private" {
    count = null_resource.az_count.triggers.total
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, null_resource.az_count.triggers.total + count.index)
    map_public_ip_on_launch = false
    availability_zone = lookup(null_resource.az_names, count.index)

    tags = null_resource.tags.triggers.tags
}

resource "aws_security_group" "public_sg" {
    name = "${local.project_prefix}_public_sg"
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [local.default_route]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [local.default_route]
    }
}

resource "aws_security_group" "private_sg" {
    name = "${local.project_prefix}private_sg"
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = aws_subnet.public[*].cidr_block
    }

    ingress {
        from_port = 80
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [local.default_route]
        security_groups = [aws_security_group.webserver_alb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [local.default_route]
    }
}

resource "aws_internet_gateway" "main_vpc_ig" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(null_resource.tags.triggers, map("Name", "${local.project_prefix}_ig"))
}

resource "aws_eip" "nat" {
  count = null_resource.az_count.triggers.total
  vpc              = true
}

resource "aws_nat_gateway" "nat" {
  count = null_resource.az_count.triggers.total
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = null_resource.tags.triggers
  depends_on = [aws_internet_gateway.main_vpc_ig]
}

resource "aws_route_table" "public_subnet_rt" {
  depends_on = [
    aws_vpc.main_vpc,
    aws_internet_gateway.main_vpc_ig
  ]
  vpc_id = aws_vpc.main_vpc.id
  tags =  merge(null_resource.tags.triggers, map("name", "${local.project_prefix}_public_rt"))
}

resource "aws_route_table" "private_subnet_rt" {
  depends_on = [
    aws_vpc.main_vpc,
    aws_internet_gateway.main_vpc_ig
  ]
  vpc_id = aws_vpc.main_vpc.id
  tags =  merge(null_resource.tags.triggers, map("name", "${local.project_prefix}_private_rt"))
}

resource "aws_route" "public" {
  count = null_resource.az_count.triggers.total
  route_table_id = aws_route_table.public_subnet_rt[count.index].id
  destination_cidr_block = local.default_route
  gateway_id = aws_internet_gateway.main_vpc_ig.id
}

resource "aws_route" "private" {
  count = null_resource.az_count.triggers.total
  route_table_id = aws_route_table.private_subnet_rt[count.index].id
  destination_cidr_block = local.default_route
  nat_gateway_id = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "public" {
  count = null_resource.az_count.triggers.total
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_subnet_rt.id
}

resource "aws_route_table_association" "private" {
  count = null_resource.az_count.triggers.total
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_subnet_rt.id
}

resource "aws_instance" "bastion" {
    count = null_resource.az_count.triggers.total
    ami = var.bastion.ami
    instance_type = var.bastion.type
    vpc_security_group_ids = [aws_security_group.public_sg.id]
    subnet_id = aws_subnet.public[count.index].id
    key_name = aws_key_pair.bastion.key_name
    tags = merge(null_resource.tags.triggers, map("Name", "${local.project_prefix}-Bastion"))
}