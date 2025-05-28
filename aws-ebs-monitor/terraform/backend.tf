terraform {
  backend "s3" {
    bucket         = "ebs-monitor-prod-terraform-state"  # Use the actual bucket name from terraform-state output
    key            = "ebs-monitor/terraform.tfstate"
    region         = "us-east-1"                        # Use the same region as your state infrastructure
    encrypt        = true
    dynamodb_table = "ebs-monitor-prod-terraform-lock"  # Use the actual DynamoDB table name from terraform-state output
  }
} 