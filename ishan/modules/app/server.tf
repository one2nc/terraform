# Create Bastion Server
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app-instance1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.aws_key_pair_id
  subnet_id              = var.private_subnet1_id
  vpc_security_group_ids = [aws_security_group.private_http_ssh.id]

  tags = {
    Name = "app-instance1"
  }
}

