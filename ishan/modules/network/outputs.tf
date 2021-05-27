output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet1_id" {
  description = "The ID of the private subnet (1)"
  value       = aws_subnet.private_subnet1.id
}

output "private_subnet2_id" {
  description = "The ID of the private subnet (2)"
  value       = aws_subnet.private_subnet2.id
}

output "public_subnet1_id" {
  description = "The ID of the public subnet (1)"
  value       = aws_subnet.public_subnet1.id
}

output "public_subnet2_id" {
  description = "The ID of the public subnet (2)"
  value       = aws_subnet.public_subnet2.id
}

output "vpc_cidr_block" {
  description = "The VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_security_group.default_http_ssh.id
}

output "private_security_group_id" {
  description = "The ID of the security group to be used for private instances"
  value       = aws_security_group.private_http_ssh.id
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds_sec_grp.id
}

output "alb_default_sec_grp_id" {
  description = "The ID of the default ALB security group"
  value       = aws_security_group.alb_default_sec_grp.id
}
