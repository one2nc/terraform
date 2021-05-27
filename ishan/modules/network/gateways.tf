# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc.name}-igw"
  }
}

# Create an Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  vpc      = true

  tags = {
    Name = "${var.vpc.name}-ngw-eip"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet1.id

  tags = {
    Name = "${var.vpc.name}-ngw"
  }

  depends_on = [aws_internet_gateway.igw]
}

