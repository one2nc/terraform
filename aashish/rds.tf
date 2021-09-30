resource "aws_db_instance" "default" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "foo"
  password               = "foobarbaz"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
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
