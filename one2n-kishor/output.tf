output "public_subnets" {
  value = "${aws_subnet.public_subnet.*.id}"
}

output "security_group" {
  value = "${aws_security_group.test_sg.id}"
}

output "security_group_ec2" {
  value = "${aws_security_group.ec2_sg.id}"
}

output "security_group_rds" {
  value = "${aws_security_group.my-rds-sg.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "subnet1" {
  value = "${element(aws_subnet.public_subnet.*.id, 1 )}"
}

output "subnet2" {
  value = "${element(aws_subnet.public_subnet.*.id, 2 )}"
}

output "private_subnet1" {
  value = "${element(aws_subnet.private_subnet.*.id, 1 )}"
}

output "private_subnet2" {
  value = "${element(aws_subnet.private_subnet.*.id, 2 )}"
}

output "nat_gateway" {
  value = aws_nat_gateway.my-test-nat-gateway.*.public_ip
}

output "internet_gateway" {
  value = aws_internet_gateway.gw
}

output "alb_dns" {
  description = "DNS endpoint for application load balancer."
  value       = aws_lb.my-alb.dns_name
}

output "bastion_host_ip" {
  description = "List of Public IP addresses assigned to the bastian instances"
  value       = aws_instance.bastian_instance.*.public_ip
}

output "service_box_ip" {
  description = "Private IP addresses of service instances"
  value       = aws_instance.service_instance.*.private_ip
}

output "service_box_ip1" {
  description = "Private IP addresses of service instances"
  value       = aws_instance.service_instance_1.*.private_ip
}

output "mysql-db" {
  description = "RDS details"
  value       = {
    endpoint = aws_db_instance.my-test-sql.endpoint
    db_name = aws_db_instance.my-test-sql.name
    username = aws_db_instance.my-test-sql.username
    password = aws_db_instance.my-test-sql.password
  }
  sensitive = true
}
