output "bastion_private_key" {
  value = tls_private_key.bastion.private_key_pem
}

output "webserver_private_key" {
  value = tls_private_key.webserver.private_key_pem
}

output "bastian_a_public_ip" {
  value = aws_instance.bastion_a.public_ip
}

output "bastian_b_public_ip" {
  value = aws_instance.bastion_b.public_ip
}

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

variable "region" {
    type = string
    default ="ap-south-1"
}

provider "aws" {
    region = var.region
}

resource "aws_vpc" "sitaram_poc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "Sitaram POC"
    }
}

resource "aws_subnet" "public_a" {
    vpc_id     = aws_vpc.sitaram_poc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a"

    tags = {
        Name = "Public A"
    }
}

resource "aws_subnet" "public_b" {
    vpc_id     = aws_vpc.sitaram_poc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1b"

    tags = {
        Name = "Public B"
    }
}

resource "aws_subnet" "private_a" {
    vpc_id     = aws_vpc.sitaram_poc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-south-1a"
    tags = {
        Name = "Private A"
    }
}

resource "aws_subnet" "private_b" {
    vpc_id     = aws_vpc.sitaram_poc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "ap-south-1b"
    tags = {
        Name = "Private B"
    }
}

resource "aws_security_group" "public_subnet_sg" {
    name = "public_subnet_sg"
    vpc_id = aws_vpc.sitaram_poc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "private_subnet_sg" {
    name = "private_subnet_sg"
    vpc_id = aws_vpc.sitaram_poc.id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "rds_sg" {
    name = "rds_sg"
    vpc_id = aws_vpc.sitaram_poc.id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"]
    }
}

resource "aws_internet_gateway" "sitaram_poc_ig" {
  vpc_id = aws_vpc.sitaram_poc.id

  tags = {
    Name = "sitaram_poc_ig"
  }
}

resource "aws_eip" "nat_a" {
  vpc              = true
}
resource "aws_eip" "nat_b" {
  vpc              = true
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "NAT-A"
  }
  depends_on = [aws_internet_gateway.sitaram_poc_ig]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "NAT-B"
  }
  depends_on = [aws_internet_gateway.sitaram_poc_ig]
}

resource "aws_route_table" "public_subnet_rt" {
  depends_on = [
    aws_vpc.sitaram_poc,
    aws_internet_gateway.sitaram_poc_ig
  ]

  vpc_id = aws_vpc.sitaram_poc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sitaram_poc_ig.id
  }

  tags = {
    Name = "Route Table for IG"
  }
}

resource "aws_route_table_association" "rt_ig_astn_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_subnet_rt.id
}
resource "aws_route_table_association" "rt_ig_astn_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_subnet_rt.id
}

resource "aws_route_table" "nat_route_a" {
  depends_on = [
    aws_nat_gateway.nat_a
  ]

  vpc_id = aws_vpc.sitaram_poc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "Route Table for NAT A"
  }

}

resource "aws_route_table" "nat_route_b" {
  depends_on = [
    aws_nat_gateway.nat_b
  ]

  vpc_id = aws_vpc.sitaram_poc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "Route Table for NAT B"
  }

}

resource "aws_route_table_association" "nat_rt_astn_a" {
  depends_on = [
    aws_route_table.nat_route_a
  ]

  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.nat_route_a.id
}

resource "aws_route_table_association" "nat_rt_astn_b" {
  depends_on = [
    aws_route_table.nat_route_b
  ]

  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.nat_route_b.id
}


resource "aws_instance" "bastion_a" {
    ami = "ami-0cda377a1b884a1bc"
    instance_type = "t3.nano"
    vpc_security_group_ids = [aws_security_group.public_subnet_sg.id]
    subnet_id = aws_subnet.public_a.id
    key_name = aws_key_pair.bastion.key_name
    tags = {
        Name = "Bastion A"
    }
}

resource "aws_instance" "bastion_b" {
    ami = "ami-0cda377a1b884a1bc"
    instance_type = "t3.nano"
    vpc_security_group_ids = [aws_security_group.public_subnet_sg.id]
    subnet_id = aws_subnet.public_b.id
    key_name = aws_key_pair.bastion.key_name
    tags = {
        Name = "Bastion B"
    }
}

resource "aws_instance" "webserver_a" {
    ami = "ami-0cda377a1b884a1bc"
    instance_type = "t3.nano"
    vpc_security_group_ids = [aws_security_group.private_subnet_sg.id]
    subnet_id = aws_subnet.private_a.id
    key_name = aws_key_pair.webserver.key_name
    tags = {
        Name = "Webserver A"
    }
}

resource "aws_instance" "webserver_b" {
    ami = "ami-0cda377a1b884a1bc"
    instance_type = "t3.nano"
    vpc_security_group_ids = [aws_security_group.private_subnet_sg.id]
    subnet_id = aws_subnet.private_b.id
    key_name = aws_key_pair.webserver.key_name
    tags = {
        Name = "Webserver B"
    }
}

resource "aws_db_subnet_group" "rds_sg" {
  name       = "rds_private_sg"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Sitaram RDS SG"
  }
}

resource "aws_db_instance" "rds" {
    allocated_storage    = 20
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t2.micro"
    name                 = "mydb"
    username             = "sitaram"
    password             = "batmanandrobin"
    parameter_group_name = "default.mysql5.7"
    db_subnet_group_name = aws_db_subnet_group.rds_sg.name
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
}