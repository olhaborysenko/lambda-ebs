locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = "devops"
  }

  # Default IOPS values for different volume types
  default_iops = {
    "io1" = 3000
    "io2" = 3000
    "gp3" = 3000
  }

  # Default throughput values for gp3 volumes
  default_throughput = {
    "gp3" = 125
  }
} 