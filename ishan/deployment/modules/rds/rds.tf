resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet"
  subnet_ids = [var.private_subnet1_id, var.private_subnet2_id]

  tags = {
    Name = "rds-subnet"
  }
}

# Create MySql RDS instance
resource "aws_db_instance" "app_rds_postgres" {
  allocated_storage      = 10
  engine                 = "postgres"
  engine_version         = "13.2"
  instance_class         = "db.t3.micro"
  name                   = "appdb"
  username               = var.rds_username
  password               = var.rds_password
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.id
  vpc_security_group_ids = [var.rds_security_group_id]
}
