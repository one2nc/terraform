locals {
  subnet_ids = aws_subnet.private_subnet.*.id
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = local.subnet_ids
}


resource "aws_db_instance" "my-test-sql" {
  instance_class          = var.db_instance
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  storage_type            = "gp2"
  allocated_storage       = 20
  name                    = var.db_name
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  db_subnet_group_name    = "${aws_db_subnet_group.rds_subnet_group.name}"
  vpc_security_group_ids  = ["${aws_security_group.my-rds-sg.id}"]
}


# Security Group for RDS
resource "aws_security_group" "my-rds-sg" {
  name   = "my-rds-sg"
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group_rule" "my-rds-sg-rule" {
  from_port         = 3306
  protocol          = "tcp"
  security_group_id = "${aws_security_group.my-rds-sg.id}"
  to_port           = 3306
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "outbound_rule" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.my-rds-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
