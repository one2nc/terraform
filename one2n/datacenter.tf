output "bastion_address" {
  value = aws_instance.bastion.*.public_ip
}

output "bastion_private_key" {
  value = tls_private_key.bastion.private_key_pem
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

variable "cidr_block" {
  type = string
}

variable "organization" {
  type = string
}

variable "env" {
  type = string
}

variable "bastion_ami" {
  type = string
  default = "ami-0dd861ee19fd50a16"
}

variable "bastion_flavour" {
  type = string
  default = "t2.nano"
}

variable "bastion_count" {
  type = number
  default = 1
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
}

resource "aws_key_pair" "bastion" {
  key_name = "bastion"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "public" {
  count = lookup(null_resource.zone_count.triggers, "total")
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index)
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "private" {
  count = lookup(null_resource.zone_count.triggers, "total")
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index + 4)
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "nat" {
  count = lookup(null_resource.zone_count.triggers, "total")
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  count = lookup(null_resource.zone_count.triggers, "total")
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id = element(aws_subnet.public.*.id, 0)
}

resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.vpc.id
  name = "${var.organization}-${var.env}-bastion"
  revoke_rules_on_delete = true

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    protocol = -1
    to_port = 0
  }
}

resource "aws_security_group_rule" "bastion-22"   {
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 22
  protocol = "tcp"
  to_port = 22
  security_group_id = aws_security_group.bastion.id
  type = "ingress"
}

resource "aws_security_group_rule" "bastion-443"   {
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 443
  protocol = "tcp"
  to_port = 443
  security_group_id = aws_security_group.bastion.id
  type = "ingress"
}


resource "aws_route_table" "public" {
  count = lookup(null_resource.zone_count.triggers, "total")
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "private" {
  count = lookup(null_resource.zone_count.triggers, "total")
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public" {
  count = lookup(null_resource.zone_count.triggers, "total")
  route_table_id = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig.id
}

resource "aws_route" "private" {
  count = lookup(null_resource.zone_count.triggers, "total")
  route_table_id = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count = lookup(null_resource.zone_count.triggers, "total")
  route_table_id = element(aws_route_table.public.*.id, count.index)
  subnet_id = element(aws_subnet.public.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count = lookup(null_resource.zone_count.triggers, "total")
  route_table_id = element(aws_route_table.private.*.id, count.index)
  subnet_id = element(aws_subnet.private.*.id, count.index)
}

resource "aws_instance" "bastion" {
  count = var.bastion_count
  ami = var.bastion_ami
  associate_public_ip_address = true
  instance_type = var.bastion_flavour
  key_name = aws_key_pair.bastion.key_name
  subnet_id = element(aws_subnet.public.*.id, count.index)
  source_dest_check = false
  vpc_security_group_ids = [aws_security_group.bastion.id]
}
