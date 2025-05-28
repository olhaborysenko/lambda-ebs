terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket         = "ebs-monitor-prod-terraform-state"  # Use the same bucket as the monitoring stack
    key            = "ebs-volumes/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "ebs-monitor-prod-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Create EBS volumes
resource "aws_ebs_volume" "volumes" {
  for_each = var.volumes

  availability_zone = each.value.availability_zone
  size             = each.value.size
  type             = each.value.type
  encrypted        = each.value.encrypted
  iops             = contains(["io1", "io2", "gp3"], each.value.type) ? (
    each.value.iops != null ? each.value.iops : lookup(local.default_iops, each.value.type, null)
  ) : null
  throughput = each.value.type == "gp3" ? (
    each.value.throughput != null ? each.value.throughput : local.default_throughput["gp3"]
  ) : null
  snapshot_id = each.value.snapshot_id
  kms_key_id  = var.kms_key_id

  tags = merge(
    {
      Name = "${local.name_prefix}-${each.key}"
      Description = each.value.description
    }
  )
}

# Create AWS Backup vault and plan if backup is enabled
resource "aws_backup_vault" "ebs_vault" {
  count = var.enable_backup ? 1 : 0
  name  = "${local.name_prefix}-vault"
  
  tags = {
    Name = "${local.name_prefix}-vault"
  }
}

resource "aws_backup_plan" "ebs_backup" {
  count = var.enable_backup ? 1 : 0
  name  = "${local.name_prefix}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.ebs_vault[0].name
    schedule          = "cron(0 5 ? * * *)" # Daily at 5 AM UTC

    lifecycle {
      delete_after = 30 # Keep backups for 30 days
    }
  }

  tags = {
    Name = "${local.name_prefix}-backup-plan"
  }
}

resource "aws_backup_selection" "ebs_backup" {
  count = var.enable_backup ? 1 : 0
  name  = "${local.name_prefix}-backup-selection"
  plan_id = aws_backup_plan.ebs_backup[0].id
  iam_role_arn = aws_iam_role.backup_role[0].arn

  resources = [
    for volume in aws_ebs_volume.volumes : volume.arn
  ]
}

# Create IAM role for AWS Backup if backup is enabled
resource "aws_iam_role" "backup_role" {
  count = var.enable_backup ? 1 : 0
  name  = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-backup-role"
  }
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  count      = var.enable_backup ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role[0].name
} 