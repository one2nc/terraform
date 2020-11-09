output "bastion_private_key" {
  value = tls_private_key.bastion.private_key_pem
}

output "webserver_private_key" {
  value = tls_private_key.webserver.private_key_pem
}

output "bastian_public_ip" {
  value = aws_instance.bastion.*.public_ip
}

output "alb_dns_name" {
  value       = aws_lb.webserver_alb.dns_name
  description = "The domain name of the load balancer"
}