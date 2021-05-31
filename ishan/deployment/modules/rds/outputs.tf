output "rds_hostname" {
  description = "RDS (Postgres) hostname"
  value       = aws_db_instance.app_rds_postgres.address
}
