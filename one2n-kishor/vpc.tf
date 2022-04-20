# VPC Creation

resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-new-test-terraform-vpc"
  }
}

# Creating Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "my-test-igw"
  }
}

# Public Route Table

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "my-test-public-route"
  }
}

# Private Route Table

resource "aws_default_route_table" "private_route" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  route {
    nat_gateway_id = "${aws_nat_gateway.my-test-nat-gateway.id}"
    cidr_block     = "0.0.0.0/0"
  }

  tags = {
    Name = "my-private-route-table"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  count                   = 2
  cidr_block              = "${var.public_cidrs[count.index]}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_availability_zones [count.index]}"

  tags = {
    Name = "my-test-public-subnet.${count.index + 1}"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  count             = 2
  cidr_block        = "${var.private_cidrs[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${var.aws_availability_zones [count.index]}"

  tags = {
    Name = "my-test-private-subnet.${count.index + 1}"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc" {
  count          = 2
  route_table_id = "${aws_route_table.public_route.id}"
  subnet_id      = "${aws_subnet.public_subnet.*.id[count.index]}"
  depends_on     = ["aws_route_table.public_route", "aws_subnet.public_subnet"]
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_assoc" {
  count          = 2
  route_table_id = "${aws_default_route_table.private_route.id}"
  subnet_id      = "${aws_subnet.private_subnet.*.id[count.index]}"
  depends_on     = ["aws_default_route_table.private_route", "aws_subnet.private_subnet"]
}

# Security Group Creation
resource "aws_security_group" "test_sg" {
  name   = "my-test-sg"
  vpc_id = "${aws_vpc.main.id}"
}

# Ingress Security Port 22
resource "aws_security_group_rule" "https_inbound_access" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.test_sg.id}"
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.test_sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.test_sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

#AWS EC2 SG
 resource "aws_security_group" "ec2_sg" {
 name        = "${var.environment}-ec2-sg"
 description = "security group to allow inbound/outbound from the Application load balancer"
 vpc_id      = "${aws_vpc.main.id}"
 depends_on  = [aws_vpc.main]
 egress {
         from_port = 0
         to_port = 0
         protocol = -1
         cidr_blocks = ["0.0.0.0/0"]
     }
 ingress {
         from_port = 22
         to_port = 22
         protocol = "tcp"
         cidr_blocks = ["0.0.0.0/0"]
         security_groups = [aws_security_group.test_sg.id]
  }
}


resource "aws_eip" "my-test-eip" {
  vpc    = true
}

resource "aws_nat_gateway" "my-test-nat-gateway" {
  allocation_id = "${aws_eip.my-test-eip.id}"
  subnet_id     = "${aws_subnet.public_subnet.0.id}"
}
