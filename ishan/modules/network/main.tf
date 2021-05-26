# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc.cidr

  tags = {
    Name = var.vpc.name
  }
}

# Create a Public Subnet
resource "aws_subnet" "public-subnet1" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1.cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc.name}-public-1"
  }

  depends_on = [aws_internet_gateway.igw]
}
resource "aws_subnet" "public-subnet2" {
  availability_zone       = "us-east-1b"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet2.cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc.name}-public-2"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Create a Private Subnet
resource "aws_subnet" "private-subnet1" {
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet1.cidr

  tags = {
    Name = "${var.vpc.name}-private-1"
  }
}
resource "aws_subnet" "private-subnet2" {
  availability_zone = "us-east-1b"
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet2.cidr

  tags = {
    Name = "${var.vpc.name}-private-2"
  }
}


# Create Route table - Private Subnet
resource "aws_route_table" "route-table-private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "${var.vpc.name}-private"
  }
}

# Create Route table - Public SUbnet
resource "aws_route_table" "route-table-public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.vpc.name}-public"
  }
}

# Route Table - PrivateSubet Association
resource "aws_route_table_association" "pri1" {
  subnet_id      = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.route-table-private.id
}
resource "aws_route_table_association" "pri2" {
  subnet_id      = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.route-table-private.id
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.route-table-public.id
}
resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.route-table-public.id
}

# Create default Security Group
resource "aws_security_group" "default_http_ssh" {
  name        = "default_http_ssh"
  description = "Allow inbound http(s) and ssh traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip, aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "default_http_ssh"
  }
}

