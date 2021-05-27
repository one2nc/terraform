# Create a Public Subnet
resource "aws_subnet" "public_subnet1" {
  availability_zone       = "us-east-1a"
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet1.cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc.name}-public-1"
  }

  depends_on = [aws_internet_gateway.igw]
}
resource "aws_subnet" "public_subnet2" {
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
resource "aws_subnet" "private_subnet1" {
  availability_zone = "us-east-1a"
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet1.cidr

  tags = {
    Name = "${var.vpc.name}-private-1"
  }
}
resource "aws_subnet" "private_subnet2" {
  availability_zone = "us-east-1b"
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet2.cidr

  tags = {
    Name = "${var.vpc.name}-private-2"
  }
}

# Route Table - PrivateSubet Association
resource "aws_route_table_association" "private_subnet1_route_table" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.route_table_private.id
}
resource "aws_route_table_association" "private_subnet2_route_table" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.route_table_private.id
}

resource "aws_route_table_association" "public_subnet1_route_table" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.route_table_public.id
}
resource "aws_route_table_association" "public_subnet2_route_table" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.route_table_public.id
}

