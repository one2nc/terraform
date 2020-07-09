output "service_address" {
  value = aws_instance.service.*.private_ip
}

output "service_private_key" {
  value = tls_private_key.service.private_key_pem
}

variable "service" {
  type = object({
      ami = string
      flavour = string
      count = number
      root_disk_size = number
      root_disk_type = string
    })

  default = {
    ami = "ami-0dd861ee19fd50a16"
    flavour = "t2.medium"
    count = 1
    root_disk_size = 50
    root_disk_type = "gp2"
  }
}

resource "tls_private_key" "service" {
  algorithm = "RSA"
}

resource "aws_key_pair" "service" {
  key_name   = "service"
  public_key = tls_private_key.service.public_key_openssh
  tags = null_resource.tags.triggers
}

resource "aws_security_group" "service" {
  vpc_id                 = aws_vpc.vpc.id
  name                   = "${var.organization}-${var.env}-service"
  revoke_rules_on_delete = true

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = -1
    to_port     = 0
  }
}

resource "aws_security_group_rule" "ingress_from_bastion" {
  from_port                = 0
  protocol                 = -1
  to_port                  = 0
  security_group_id        = aws_security_group.service.id
  source_security_group_id = aws_security_group.bastion.id
  type                     = "ingress"
}

resource "aws_instance" "service" {
  count                  = var.service.count
  ami                    = var.service.ami
  instance_type          = var.service.flavour
  availability_zone      = data.aws_availability_zones.available.names[0]
  key_name               = aws_key_pair.service.key_name
  subnet_id              = aws_subnet.private.0.id
  vpc_security_group_ids = [aws_security_group.service.id]
  iam_instance_profile   = aws_iam_instance_profile.bucket_iam_profile.name

  root_block_device {
    volume_size = var.service.root_disk_size
    volume_type = var.service.root_disk_type
    delete_on_termination = true
  }

  tags                   = null_resource.tags.triggers
}
