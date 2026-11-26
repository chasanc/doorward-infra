resource "aws_kms_key" "this" {
  description         = "${var.name} secrets encryption"
  enable_key_rotation = true
}

# Only the secret shell is managed here. Put the value in with `aws secretsmanager put-secret-value`
# so it never lands in Terraform state or git.
resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.name}/app"
  description             = "Application configuration for ${var.name}; value set out of band"
  kms_key_id              = aws_kms_key.this.arn
  recovery_window_in_days = var.recovery_window_days
}
