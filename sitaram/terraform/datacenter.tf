resource "tls_private_key" "bastion" {
  algorithm = "RSA"
}

resource "aws_key_pair" "bastion" {
  key_name   = "sitaram-poc-bastion"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "tls_private_key" "webserver" {
  algorithm = "RSA"
}

resource "aws_key_pair" "webserver" {
  key_name   = "sitaram-poc-webserver"
  public_key = tls_private_key.webserver.public_key_openssh
}

resource "null_resource" "tags" {
  triggers = {
    tags = var.meta
  }
}

provider "aws" {
    region = var.region
}

resource "aws_vpc" "main_vpc" {
    cidr_block = var.vpc_cidr
    tags = null_resource.tags.triggers.tags.meta
}

resource "aws_subnet" "public" {
    count = null_resource.azs_count.triggers.total
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
    map_public_ip_on_launch = true
    availability_zone = lookup(null_resource.azs_list, count.index)

    tags = null_resource.tags.triggers.tags.meta
}

resource "aws_subnet" "private" {
    count = null_resource.azs_count.triggers.total
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = cidrsubnet(var.vpc_cidr, 8, null_resource.azs_list_count.triggers.total + count.index)
    map_public_ip_on_launch = false
    availability_zone = lookup(null_resource.azs_list, count.index)

    tags = null_resource.tags.triggers.tags
}

resource "aws_security_group" "public_sg" {
    name = "public_sg"
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [default_route]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [default_route]
    }
}

resource "aws_security_group" "private_sg" {
    name = "private_sg"
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = aws_subnet.public_sg[*].cidr_block
    }

    ingress {
        from_port = 80
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [default_route]
        security_groups = [aws_security_group.webserver_alb_sg.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [default_route]
    }
}

resource "aws_internet_gateway" "sitaram_poc_ig" {
  vpc_id = aws_vpc.main_vpc.id

  tags = null_resource.tags.triggers.tags.meta
}

resource "aws_eip" "nat" {
  count = null_resource.azs_count.triggers.total
  vpc              = true
}

resource "aws_nat_gateway" "nat_a" {
  count = null_resource.azs_count.triggers.total
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = null_resource.tags.triggers.tags.meta
  depends_on = [aws_internet_gateway.sitaram_poc_ig]
}

resource "aws_route_table" "public_subnet_rt" {
  depends_on = [
    aws_vpc.main_vpc,
    aws_internet_gateway.sitaram_poc_ig
  ]
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = default_route
    gateway_id = aws_internet_gateway.sitaram_poc_ig.id
  }

  tags =  null_resource.tags.triggers.tags.meta
}

resource "aws_route_table_association" "rt_ig_astn" {
  count = null_resource.azs_count.triggers.total
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_subnet_rt.id
}

resource "aws_route_table" "nat_route" {
  count = null_resource.azs_count.triggers.total
  depends_on = [
    aws_nat_gateway.nat[count.index]
  ]
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = default_route
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags =  null_resource.tags.triggers.tags.meta
}

resource "aws_route_table_association" "nat_rt_astn" {
  count = null_resource.azs_count.triggers.total
  depends_on = [
    aws_route_table.nat_route[count.index]
  ]

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.nat_route[count.index].id
}

resource "aws_instance" "bastion" {
    count = null_resource.azs_count.triggers.total
    ami = var.bastion.ami
    instance_type = var.bastion.type
    vpc_security_group_ids = [aws_security_group.public_sg.id]
    subnet_id = aws_subnet.public[count.index].id
    key_name = aws_key_pair.bastion.key_name
    tags = null_resource.tags.triggers.tags.meta
}