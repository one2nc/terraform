resource "aws_key_pair" "test-key" {
  key_name   = "test-key"
  public_key = "${file(var.my_public_key)}"
}

data "template_file" "init" {
  template = "${file("${path.module}/userdata.tpl")}"
}

resource "aws_instance" "bastion" {
  count                  = 2
  ami                    = "ami-0732b62d310b80e97"
  instance_type          = "${var.instance_type}"
  key_name               = "${aws_key_pair.test-key.id}"
  vpc_security_group_ids = ["${var.security_group}"]
  subnet_id              = "${element(var.subnets, count.index)}"
  user_data              = "${data.template_file.init.rendered}"

  tags = {
    Name = "bastion-${count.index + 1}"
  }
}
