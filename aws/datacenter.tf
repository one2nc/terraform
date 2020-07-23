output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "bastion_private_key" {
  value = tls_private_key.key.private_key_pem
}

output "bastion_address" {
  value = aws_instance.bastion.*.public_ip
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "worker_address" {
  value = aws_instance.worker.*.private_ip
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

variable "cidr_block" {
  type = string
}

variable "meta" {
  type = object({
    env = string
  })
}

variable "bastion" {
  type = object({
    ami     = string
    flavour = string
    count   = number
  })

  default = {
    ami     = "ami-02d55cb47e83a99a0"
    flavour = "t2.micro"
    count   = 2
  }
}

variable "worker" {
  type = object({
    ami     = string
    flavour = string
    count   = number
  })

  default = {
    ami     = "ami-02d55cb47e83a99a0"
    flavour = "t2.micro"
    count   = 2
  }
}

data "aws_availability_zones" "available" {}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key" {
  key_name   = "ssh-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "datacenter"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw"
  }
}

resource "aws_eip" "nat" {
  count = 2
  vpc   = true
  tags = {
    Name = "eip"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index + 4)
  vpc_id            = aws_vpc.vpc.id
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  tags = {
    Name = "nat-gw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public" {
  count                  = 1
  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private" {
  count                  = 1
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = 2
  route_table_id = element(aws_route_table.public.*.id, count.index)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = 2
  route_table_id = element(aws_route_table.private.*.id, count.index)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
}

resource "aws_instance" "bastion" {
  ami                    = var.bastion.ami
  count                  = var.bastion.count
  instance_type          = var.bastion.flavour
  key_name               = aws_key_pair.key.key_name
  subnet_id              = element(aws_subnet.public.*.id, count.index)
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.bastion.id]
}

resource "aws_security_group" "bastion" {
  vpc_id                 = aws_vpc.vpc.id
  name                   = "${var.meta.env}-bastion"
  revoke_rules_on_delete = true
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = -1
    to_port     = 0
  }
}

resource "aws_security_group_rule" "bastion-22" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  to_port           = 22
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
}

resource "aws_security_group_rule" "bastion-443" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
}

resource "aws_instance" "worker" {
  ami                    = var.worker.ami
  count                  = var.worker.count
  instance_type          = var.worker.flavour
  key_name               = aws_key_pair.key.key_name
  subnet_id              = element(aws_subnet.private.*.id, count.index)
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.worker.id]
}

resource "aws_security_group" "worker" {
  vpc_id                 = aws_vpc.vpc.id
  name                   = "${var.meta.env}-worker"
  revoke_rules_on_delete = true
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = -1
    to_port     = 0
  }
}

resource "aws_security_group_rule" "worker-22" {
  from_port                = 22
  protocol                 = "tcp"
  to_port                  = 22
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.bastion.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-443" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  security_group_id = aws_security_group.worker.id
  type              = "ingress"
}
