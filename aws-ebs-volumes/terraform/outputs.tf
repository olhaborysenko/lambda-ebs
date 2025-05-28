output "volume_ids" {
  description = "Map of volume names to their IDs"
  value = {
    for k, v in aws_ebs_volume.volumes : k => v.id
  }
}

output "volume_arns" {
  description = "Map of volume names to their ARNs"
  value = {
    for k, v in aws_ebs_volume.volumes : k => v.arn
  }
}

output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault"
  value       = var.enable_backup ? aws_backup_vault.ebs_vault[0].arn : null
}

output "backup_plan_arn" {
  description = "ARN of the AWS Backup plan"
  value       = var.enable_backup ? aws_backup_plan.ebs_backup[0].arn : null
}

output "backup_role_arn" {
  description = "ARN of the AWS Backup IAM role"
  value       = var.enable_backup ? aws_iam_role.backup_role[0].arn : null
} 