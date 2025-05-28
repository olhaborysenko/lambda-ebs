# AWS EBS Volume Monitoring

This project implements a serverless solution to monitor EBS volumes and snapshots in AWS, collecting metrics daily and storing them in CloudWatch.

## Metrics Collected

The following metrics are collected and stored in CloudWatch under the `EBSMonitoring` namespace:

- Number of unattached EBS volumes
- Total size of unattached EBS volumes
- Number of unencrypted EBS volumes
- Number of unencrypted EBS snapshots

## Architecture

The solution uses the following AWS services:

- AWS Lambda: Executes the monitoring function
- Amazon EventBridge: Schedules daily execution of the Lambda function
- Amazon CloudWatch: Stores the collected metrics
- AWS IAM: Manages permissions for the Lambda function

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 0.14
- Python 3.9

## Directory Structure

```
aws-ebs-monitor/
├── src/
│   ├── ebs_monitor.py
│   └── requirements.txt
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── lambda.zip (generated)
```

## Deployment

1. Clone this repository
2. Navigate to the project directory:
   ```bash
   cd aws-ebs-monitor
   ```

3. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

4. Review the Terraform plan:
   ```bash
   terraform plan
   ```

5. Apply the infrastructure:
   ```bash
   terraform apply
   ```

## Configuration

You can customize the deployment by modifying the following variables in `terraform/variables.tf`:

- `aws_region`: AWS region to deploy the resources (default: us-east-1)
- `cloudwatch_namespace`: CloudWatch namespace for metrics (default: EBSMonitoring)

## Monitoring

After deployment, you can view the collected metrics in CloudWatch:

1. Open the AWS CloudWatch console
2. Navigate to "Metrics"
3. Select the "EBSMonitoring" namespace
4. View the available metrics:
   - UnattachedVolumesCount
   - UnattachedVolumesTotalSize
   - UnencryptedVolumesCount
   - UnencryptedSnapshotsCount

## Clean Up

To remove all created resources:

```bash
cd terraform
terraform destroy
```

## Security Considerations

- The Lambda function uses IAM roles with least privilege access
- All permissions are explicitly defined in the Terraform configuration
- The solution only requires read access to EC2 resources and write access to CloudWatch metrics 