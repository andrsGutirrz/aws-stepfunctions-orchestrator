# Core Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "my-serverless-app"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}


# EventBridge Variables
variable "eventbridge_schedule" {
  description = "EventBridge schedule expression (cron or rate)"
  type        = string
  default     = "rate(60 minutes)"
}

variable "eventbridge_enabled" {
  description = "Enable EventBridge scheduled trigger"
  type        = bool
  default     = false
}

# Secrets Variables
variable "openai_api_key" {
  description = "OpenAI API Key"
  type        = string
  default     = "sk-placeholder-key-replace-with-real-key"
  sensitive   = true
}

variable "google_drive_folder_id" {
  description = "Google Drive Folder ID"
  type        = string
  default     = "placeholder-folder-id-replace-with-real-id"
  sensitive   = true
}