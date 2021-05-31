resource "aws_instance" "app_public_instance1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.instance_key.id
  subnet_id              = var.public_subnet1_id
  vpc_security_group_ids = [var.default_security_group_id]

  tags = {
    Name = "app-instance1"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt -y install nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.root}/.ssh/terra_rsa")
      host        = "${self.public_ip}"
    }
  }
}

resource "aws_instance" "app_public_instance2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.instance_key.id
  subnet_id              = var.public_subnet2_id
  vpc_security_group_ids = [var.default_security_group_id]

  tags = {
    Name = "app-instance2"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt -y install nginx"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.root}/.ssh/terra_rsa")
      host        = "${self.public_ip}"
    }
  }

}

