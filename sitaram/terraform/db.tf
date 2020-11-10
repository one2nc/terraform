output "mysql_host_address" {
  value = aws_db_instance.rds.address
}

output "mysql_host_username" {
  value = var.mysql_db.username
}

output "mysql_host_password" {
  value     = var.mysql_db.password
  sensitive = true
}

variable "mysql_db" {
  type = object({
    instance_type  = string
    name           = string
    username       = string
    password       = string
    storage        = number
    storage_type   = string
    engine         = string
    engine_version = string
  })
}

resource "aws_security_group" "rds_sg" {
  name   = "${local.project_prefix}_rds_sg"
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.private[*].cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.private[*].cidr_block
  }
}

resource "aws_db_subnet_group" "rds_sg" {
  name       = "${local.project_prefix}_rds_private_sg"
  subnet_ids = aws_subnet.private[*].id

  tags = null_resource.tags.triggers
}

resource "aws_db_instance" "rds" {
  allocated_storage      = var.mysql_db.storage
  storage_type           = var.mysql_db.storage_type
  engine                 = var.mysql_db.engine
  engine_version         = var.mysql_db.engine_version
  instance_class         = var.mysql_db.instance_type
  name                   = var.mysql_db.name
  username               = var.mysql_db.username
  password               = var.mysql_db.password
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.rds_sg.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}
