output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet1_id" {
  description = "The ID of the private subnet (1)"
  value       = aws_subnet.private-subnet1.id
}

output "private_subnet2_id" {
  description = "The ID of the private subnet (2)"
  value       = aws_subnet.private-subnet2.id
}

output "vpc_cidr_block" {
  description = "The VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "aws_key_pair_id" {
  description = "The AWS key pair required to launch instance"
  value = aws_key_pair.instance-key.id
}
