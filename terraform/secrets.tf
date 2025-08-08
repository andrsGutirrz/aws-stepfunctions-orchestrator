# AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${local.app_name}-secrets"
  description             = "Secrets for ${local.app_name} application"
  recovery_window_in_days = 7

  tags = local.common_tags
}

# AWS Secrets Manager Secret Version
resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  
  secret_string = jsonencode({
    OPENAI_API_KEY         = var.openai_api_key
    GOOGLE_DRIVE_FOLDER_ID = var.google_drive_folder_id
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}