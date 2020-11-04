resource "aws_instance" "webserver_a" {
    ami = "ami-0cda377a1b884a1bc"
    instance_type = "t3.nano"
    vpc_security_group_ids = [aws_security_group.private_subnet_sg.id]
    subnet_id = aws_subnet.private_a.id
    key_name = aws_key_pair.webserver.key_name
    tags = {
        Name = "Webserver A"
    }
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
              EOF
}

resource "aws_instance" "webserver_b" {
    ami = "ami-0cda377a1b884a1bc"
    instance_type = "t3.nano"
    vpc_security_group_ids = [aws_security_group.private_subnet_sg.id]
    subnet_id = aws_subnet.private_b.id
    key_name = aws_key_pair.webserver.key_name
    tags = {
        Name = "Webserver B"
    }
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
              EOF
}
