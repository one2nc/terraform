variable "rds" {
  type = object({
    name     = string
    username = string
    password = string
  })
}

resource "aws_db_instance" "default" {
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = var.rds.name
  username               = var.rds.username
  password               = var.rds.password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${local.project_name}-subnet-grp"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "${local.project_name}-rds-sg"
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = aws_subnet.private[*].cidr_block
  }

  tags = {
    Name = "${local.project_name}-rds-sg"
  }
}
