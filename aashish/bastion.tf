output "bastion_private_key" {
  value     = tls_private_key.bastion.private_key_pem
  sensitive = true
}

variable "bastion" {
  type = object({
    ami           = string,
    instance_type = string
  })
}

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion"
  public_key = tls_private_key.bastion.public_key_openssh
  tags       = local.tags
}

resource "aws_security_group" "bastion" {
  name   = "${local.project_name}-bastion-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress = [{
    cidr_blocks      = [local.default_route]
    description      = "SSH"
    from_port        = 22
    protocol         = "tcp"
    to_port          = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  egress = [{
    cidr_blocks      = [local.default_route]
    description      = "Public"
    from_port        = 0
    protocol         = -1
    to_port          = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  tags = merge({
    Name = "${local.project_name}-bastion-sg"
  }, local.tags)
}

resource "aws_instance" "bastion" {
  count                  = local.no_of_az
  ami                    = var.bastion.ami
  instance_type          = var.bastion.instance_type
  key_name               = aws_key_pair.bastion.key_name
  subnet_id              = aws_subnet.public[count.index].id
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.bastion.id]
  tags = merge({
    Name = "${local.project_name}-bastion-${count.index}"
  }, local.tags)
}
