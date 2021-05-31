resource "aws_instance" "app_private_instance1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.instance_key.id
  subnet_id              = var.private_subnet1_id
  vpc_security_group_ids = [var.private_security_group_id]

  tags = {
    Name = "app-private-instance1"
  }
}
