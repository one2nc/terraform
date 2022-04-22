output "vpc_id" {
  value = aws_vpc.main.id
}

output "nat_gateway" {
  value = aws_nat_gateway.nat_gateway.*.public_ip
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
  value = {
    endpoint = aws_db_instance.my-test-sql.endpoint
    db_name  = aws_db_instance.my-test-sql.name
    username = aws_db_instance.my-test-sql.username
    password = aws_db_instance.my-test-sql.password
  }
  sensitive = true
}
