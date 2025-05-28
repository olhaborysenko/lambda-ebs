locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = "devops"
    Component   = "terraform-state"
  }

  # Generate bucket name if not provided
  state_bucket = var.state_bucket_name != null ? var.state_bucket_name : "${local.name_prefix}-terraform-state"
  
  dynamodb_table_name = "${local.name_prefix}-terraform-lock"
} 