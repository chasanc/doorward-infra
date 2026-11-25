output "secret_arn" {
  description = "Application secret ARN."
  value       = aws_secretsmanager_secret.app.arn
}

output "kms_key_arn" {
  description = "Key encrypting the secret; readers need kms:Decrypt on it."
  value       = aws_kms_key.this.arn
}
