terraform {
  backend "s3" {
    bucket = "in.ashnehete.terraform"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}

variable "region" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "author" {
  type = string
}

provider "aws" {
  region = var.region
}

locals {
  project_name = "${var.project}-${var.env}"
  tags = {
    Author = var.author
  }

  no_of_az = length(data.aws_availability_zones.available.names)

  default_route = "0.0.0.0/0"
}

data "aws_availability_zones" "available" {
  state         = "available"
  exclude_names = ["ap-south-1c"]
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.cidr_block

  tags = merge({
    Name = "${local.project_name}-vpc"
  }, local.tags)
}

# Subnets
resource "aws_subnet" "public" {
  count                   = local.no_of_az
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 3, count.index)
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${local.project_name}-public-subnet-${count.index}"
  }, local.tags)
}

resource "aws_subnet" "private" {
  count                   = local.no_of_az
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 3, local.no_of_az + count.index)
  map_public_ip_on_launch = false

  tags = merge({
    Name = "${local.project_name}-private-subnet-${count.index}"
  }, local.tags)
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge({
    Name = "${local.project_name}-igw"
  }, local.tags)
}

# NAT
resource "aws_eip" "nat" {
  count = local.no_of_az
  vpc   = true

  tags = merge({
    Name = "${local.project_name}-eip-${count.index}"
  }, local.tags)

  depends_on = [
    aws_internet_gateway.main_igw
  ]
}

resource "aws_nat_gateway" "nat" {
  count         = local.no_of_az
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge({
    Name = "${local.project_name}-nat-${count.index}"
  }, local.tags)
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  depends_on = [
    aws_vpc.main_vpc,
    aws_internet_gateway.main_igw
  ]

  tags = merge({
    Name = "${local.project_name}-rt-public"
  }, local.tags)
}

resource "aws_route_table" "private" {
  count  = local.no_of_az
  vpc_id = aws_vpc.main_vpc.id

  depends_on = [
    aws_vpc.main_vpc,
    aws_internet_gateway.main_igw
  ]

  tags = merge({
    Name = "${local.project_name}-rt-private-${count.index}"
  }, local.tags)
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = local.default_route
  gateway_id             = aws_internet_gateway.main_igw.id
}

resource "aws_route" "private" {
  count                  = local.no_of_az
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = local.default_route
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "public" {
  count          = local.no_of_az
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = local.no_of_az
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
