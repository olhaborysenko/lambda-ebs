# Terraform State Infrastructure

This configuration creates the necessary infrastructure for storing Terraform state files remotely and securely in AWS.

## Resources Created

- S3 bucket for storing Terraform state files
  - Versioning enabled
  - Server-side encryption enabled
  - Public access blocked
- DynamoDB table for state locking
  - Point-in-time recovery enabled
  - PAY_PER_REQUEST billing mode

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0.0

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the configuration:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. After applying, note the outputs for use in other Terraform configurations:
   - `state_bucket_name`: Name of the created S3 bucket
   - `dynamodb_table_name`: Name of the created DynamoDB table

## Configuration

You can customize the deployment by creating a `terraform.tfvars` file:

```hcl
aws_region = "us-east-1"
project = "ebs-monitor"
environment = "prod"
state_bucket_name = "my-custom-terraform-state" # Optional
force_destroy_state = false
```

## Using the State Backend

After creating the state infrastructure, you can configure other Terraform projects to use it. Add the following to your Terraform configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "YOUR_BUCKET_NAME"
    key            = "path/to/terraform.tfstate"
    region         = "YOUR_REGION"
    encrypt        = true
    dynamodb_table = "YOUR_DYNAMODB_TABLE"
  }
}
```

Replace the placeholders with the actual values from the outputs.

## Security Features

- Server-side encryption enabled for the S3 bucket
- All public access blocked
- Versioning enabled for state files
- DynamoDB table for state locking
- Point-in-time recovery enabled for the DynamoDB table

## Clean Up

To remove all created resources:

```bash
terraform destroy
```

**Note**: Make sure all other Terraform configurations using this state backend are destroyed first. 