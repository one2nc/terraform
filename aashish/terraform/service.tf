output "service_private_key" {
  value     = tls_private_key.service.private_key_pem
  sensitive = true
}

variable "service" {
  type = object({
    ami           = string
    instance_type = string
    instances = map(object({
      az         = number
      extra_disk = number
    }))
  })
}

locals {
  extra_disks = { for key, value in var.service.instances : key => value if value.extra_disk != 0 }
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
  for_each = var.service.instances

  ami                    = var.service.ami
  instance_type          = var.service.instance_type
  key_name               = aws_key_pair.service.key_name
  subnet_id              = element(aws_subnet.private.*.id, each.value.az)
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.service.id]
  tags = merge({
    Name = "${local.project_name}-${each.key}"
  }, local.tags)
}

resource "aws_ebs_volume" "service_extra" {
  for_each = local.extra_disks

  availability_zone = element(data.aws_availability_zones.available.names, each.value.az)
  size              = each.value.extra_disk
  type              = "gp3"
}

resource "aws_volume_attachment" "ebs_att" {
  for_each = local.extra_disks

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.service_extra[each.key].id
  instance_id = aws_instance.service[each.key].id
}
