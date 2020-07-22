output "instance_id" {
  value = "${element(aws_instance.bastion.*.id, 1)}"
}

output "server_ip" {
  value = "${join(",", aws_instance.bastion.*.public_ip)}"
}
