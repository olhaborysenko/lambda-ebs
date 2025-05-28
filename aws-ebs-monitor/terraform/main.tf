terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Create Lambda IAM role
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-lambda-role"
  description = "IAM role for EBS monitoring Lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-lambda-role"
  }
}

# Create Lambda IAM policy
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Create Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "ebs_monitor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = local.lambda_name
  description      = "Monitors EBS volumes and snapshots for compliance and cost optimization"
  role            = aws_iam_role.lambda_role.arn
  handler         = "ebs_monitor.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory

  environment {
    variables = {
      CLOUDWATCH_NAMESPACE = var.cloudwatch_namespace
    }
  }

  tags = {
    Name = local.lambda_name
  }
}

# Create CloudWatch Log Group with retention
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = local.lambda_log_group
  retention_in_days = 30

  tags = {
    Name = local.lambda_log_group
  }
}

# Create EventBridge rule
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "${local.name_prefix}-daily-trigger"
  description         = "Triggers EBS monitoring Lambda function daily"
  schedule_expression = "cron(0 0 * * ? *)"  # Run at midnight UTC every day
  
  tags = {
    Name = "${local.name_prefix}-daily-trigger"
  }
}

# Create EventBridge target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "${local.name_prefix}-lambda"
  arn       = aws_lambda_function.ebs_monitor.arn
}

# Grant EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "eventbridge_lambda" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
} 