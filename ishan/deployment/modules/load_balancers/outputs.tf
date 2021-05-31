output "alb_dns_name" {
  description = "DNS Name of application load balancer"
  value       = aws_lb.main.dns_name
}
