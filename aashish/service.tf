output "service_private_key" {
  value     = tls_private_key.service.private_key_pem
  sensitive = true
}

variable "service" {
  type = list(object({
    name          = string
    ami           = string,
    instance_type = string,
    az            = number
  }))
}

resource "tls_private_key" "service" {
  algorithm = "RSA"
}

resource "aws_key_pair" "service" {
  key_name   = "service"
  public_key = tls_private_key.service.public_key_openssh
  tags       = local.tags
}

resource "aws_security_group" "service" {
  name   = "${local.project_name}-service-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress = [{
    cidr_blocks      = []
    description      = "Local"
    from_port        = 0
    protocol         = -1
    to_port          = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = [aws_security_group.bastion.id]
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
    Name = "${local.project_name}-service-sg"
  }, local.tags)
}

resource "aws_instance" "service" {
  count                  = length(var.service)
  ami                    = var.service[count.index].ami
  instance_type          = var.service[count.index].instance_type
  key_name               = aws_key_pair.service.key_name
  subnet_id              = element(aws_subnet.private.*.id, var.service[count.index].az)
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.service.id]
  tags = merge({
    Name = "${local.project_name}-${var.service[count.index].name}"
  }, local.tags)
}
