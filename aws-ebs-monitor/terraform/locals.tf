locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = "devops"
  }

  lambda_name = "${local.name_prefix}-volume-monitor"
  
  lambda_log_group = "/aws/lambda/${local.lambda_name}"
} 