# PEM file Creation
resource "tls_private_key" "aws-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "bastian"       # Create "Bastian pem file" to AWS!!
  public_key = tls_private_key.aws-key.public_key_openssh

  provisioner "local-exec" { # Create "bastian.pem" to your computer!!
    command = "echo '${tls_private_key.aws-key.private_key_pem}' > ./bastian.pem"
  }
}

# AWS EC2 Creation

 resource "aws_instance" "bastian_instance" {
   ami                         = var.aws_ami
   instance_type               = var.instance
   count                       = var.bastian_count
   associate_public_ip_address = true
   subnet_id                   = "${aws_subnet.public_subnet.*.id[count.index]}"
   vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
   key_name                    = var.key_name
   depends_on                  = [aws_subnet.public_subnet]

   tags = {
     Name = "BastianAppServerInstance-${count.index + 1}"
   }
 }

resource "aws_instance" "service_instance" {
   ami                         = var.aws_ami
   instance_type               = var.instance
   count                       = var.instance_count
   associate_public_ip_address = "false"
   subnet_id                   = "${aws_subnet.private_subnet.*.id[count.index]}"
   vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
   key_name                    = var.key_name
   depends_on                  = [aws_subnet.private_subnet]


   tags = {
     Name = "ServiceAppServerInstance-${count.index + 1}"
   }
 }
 resource "aws_instance" "service_instance_1" {
    ami                         = var.aws_ami
    instance_type               = var.instance
    count                       = var.instance_count_1
    associate_public_ip_address = "false"
    subnet_id                   = "${aws_subnet.private_subnet.*.id[count.index]}"
    vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
    key_name                    = var.key_name
    depends_on                  = [aws_subnet.private_subnet]


    tags = {
      Name = "ServiceAppServerInstance-${count.index + 1}"
    }
  }


 resource "aws_ebs_volume" "ebs_storage" {
   count             = var.instance_count
   availability_zone = var.aws_availability_zones[count.index % length(var.aws_availability_zones)]
   size              = 8


   tags = {
     Name = "storage-service-box-${count.index}"
   }
 }

 resource "aws_ebs_volume" "ebs_storage1" {
   count             = var.instance_count_1
   availability_zone = var.aws_availability_zones[count.index % length(var.aws_availability_zones)]
   size              = 8


   tags = {
     Name = "storage-service-box-${count.index}"
   }
 }

 resource "aws_volume_attachment" "service_volume_attach" {
   count       = var.instance_count
   device_name = "/dev/sdh"
   volume_id   = aws_ebs_volume.ebs_storage[count.index].id
   instance_id = aws_instance.service_instance[count.index].id
 }

 resource "aws_volume_attachment" "service_volume_attach1" {
   count       = var.instance_count_1
   device_name = "/dev/sdh"
   volume_id   = aws_ebs_volume.ebs_storage1[count.index].id
   instance_id = aws_instance.service_instance_1[count.index].id
 }
