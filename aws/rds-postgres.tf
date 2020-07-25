variable "db_instance" {
  type = string
}

resource "aws_db_instance" "test-postgres" {
  instance_class          = var.db_instance
  engine                  = "postgres"
  engine_version          = "11.6"
  multi_az                = false
  storage_type            = "gp2"
  allocated_storage       = 20
  name                    = "testdb"
  username                = "testuser"
  password                = "testpass123"
  backup_window           = "00:30-01:00"
  backup_retention_period = "1"
  db_subnet_group_name    = aws_db_subnet_group.db-subnet.name
  vpc_security_group_ids  = [aws_security_group.db-sg.id]
}

resource "aws_db_subnet_group" "db-subnet" {
  name       = "db-subnet"
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_security_group" "db-sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
