output "endpoint" {
  description = "Database host:port."
  value       = aws_db_instance.this.endpoint
}

output "master_secret_arn" {
  description = "Secrets Manager secret holding the generated master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
