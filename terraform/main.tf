# Configure Terraform
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = "personal"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  app_name    = var.app_name
  environment = var.environment
  common_tags = {
    Project     = local.app_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

