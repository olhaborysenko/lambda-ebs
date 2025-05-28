variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name for resource tagging"
  type        = string
  default     = "ebs-volumes"
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "volumes" {
  description = "Map of EBS volumes to create"
  type = map(object({
    size              = number
    type             = string
    availability_zone = string
    encrypted        = bool
    iops             = optional(number)
    throughput       = optional(number)
    snapshot_id      = optional(string)
    description      = optional(string)
  }))
  default = {
    "volume1" = {
      size              = 100
      type             = "gp3"
      availability_zone = "us-east-1a"
      encrypted        = true
      description      = "General purpose EBS volume"
    },
    "volume2" = {
      size              = 500
      type             = "io2"
      availability_zone = "us-east-1b"
      encrypted        = true
      iops             = 3000
      description      = "High-performance EBS volume"
    }
  }

  validation {
    condition = alltrue([
      for k, v in var.volumes : contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], v.type)
    ])
    error_message = "Volume type must be one of: gp2, gp3, io1, io2, st1, sc1, standard."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for EBS encryption (optional)"
  type        = string
  default     = null
}

variable "enable_backup" {
  description = "Enable automatic backups using AWS Backup"
  type        = bool
  default     = true
} 