output "app_public_instance1_id" {
  description = "Instance id of public app instance (1)"
  value       = aws_instance.app_public_instance1.id
}

output "app_public_instance2_id" {
  description = "Instance id of public app instance (2)"
  value       = aws_instance.app_public_instance2.id
}
