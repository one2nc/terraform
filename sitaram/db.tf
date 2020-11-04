resource "aws_security_group" "rds_sg" {
    name = "rds_sg"
    vpc_id = aws_vpc.sitaram_poc.id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.private_subnet_a_cidr, var.private_subnet_b_cidr]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [var.private_subnet_a_cidr, var.private_subnet_b_cidr]
    }
}

resource "aws_db_subnet_group" "rds_sg" {
  name       = "rds_private_sg"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Sitaram RDS SG"
  }
}

resource "aws_db_instance" "rds" {
    allocated_storage    = 20
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "5.7"
    instance_class       = "db.t2.micro"
    name                 = "mydb"
    username             = "sitaram"
    password             = "batmanandrobin"
    parameter_group_name = "default.mysql5.7"
    db_subnet_group_name = aws_db_subnet_group.rds_sg.name
    vpc_security_group_ids = [aws_security_group.rds_sg.id]
}
