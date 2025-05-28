output "lambda_function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.ebs_monitor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.ebs_monitor.arn
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch Log Group for Lambda function"
  value       = local.lambda_log_group
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_trigger.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "cloudwatch_namespace" {
  description = "CloudWatch namespace where metrics are published"
  value       = var.cloudwatch_namespace
} 