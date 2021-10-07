variable "service" {
  type = object({
    count = number
    ami   = string
    type  = string
  })
}

resource "aws_instance" "webserver" {
  count                  = var.service.count
  ami                    = var.service.ami
  instance_type          = var.service.type
  vpc_security_group_ids = aws_security_group.private_sg[*].id
  subnet_id              = aws_subnet.private[count.index].id
  key_name               = aws_key_pair.webserver.key_name
  tags                   = merge(null_resource.tags.triggers, map("Name", "${local.project_prefix}_webserver"))
}