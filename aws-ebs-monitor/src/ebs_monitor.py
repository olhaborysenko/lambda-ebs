import boto3
import os
import logging
from datetime import datetime
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_unattached_volumes(ec2_client):
    """Get unattached EBS volumes and their total size"""
    try:
        logger.info("Checking for unattached EBS volumes...")
        volumes = ec2_client.describe_volumes(
            Filters=[{'Name': 'status', 'Values': ['available']}]
        )['Volumes']
        
        total_size = sum(v['Size'] for v in volumes)
        logger.info(f"Found {len(volumes)} unattached volumes with total size of {total_size} GB")
        return len(volumes), total_size
    except ClientError as e:
        logger.error(f"Error getting unattached volumes: {str(e)}")
        raise

def get_unencrypted_volumes(ec2_client):
    """Get number of unencrypted EBS volumes"""
    try:
        logger.info("Checking for unencrypted EBS volumes...")
        volumes = ec2_client.describe_volumes(
            Filters=[{'Name': 'encrypted', 'Values': ['false']}]
        )['Volumes']
        
        logger.info(f"Found {len(volumes)} unencrypted volumes")
        # Log details of unencrypted volumes for better visibility
        for volume in volumes:
            logger.info(f"Unencrypted volume found: ID={volume['VolumeId']}, "
                       f"Size={volume['Size']}GB, Type={volume['VolumeType']}, "
                       f"AZ={volume['AvailabilityZone']}")
        return len(volumes)
    except ClientError as e:
        logger.error(f"Error getting unencrypted volumes: {str(e)}")
        raise

def get_unencrypted_snapshots(ec2_client):
    """Get number of unencrypted snapshots"""
    try:
        logger.info("Checking for unencrypted snapshots...")
        snapshots = ec2_client.describe_snapshots(
            OwnerIds=['self'],
            Filters=[{'Name': 'encrypted', 'Values': ['false']}]
        )['Snapshots']
        
        logger.info(f"Found {len(snapshots)} unencrypted snapshots")
        # Log details of unencrypted snapshots for better visibility
        for snapshot in snapshots:
            logger.info(f"Unencrypted snapshot found: ID={snapshot['SnapshotId']}, "
                       f"Size={snapshot.get('VolumeSize', 'N/A')}GB, "
                       f"Description={snapshot.get('Description', 'No description')}")
        return len(snapshots)
    except ClientError as e:
        logger.error(f"Error getting unencrypted snapshots: {str(e)}")
        raise

def put_metric(cloudwatch_client, metric_name, value, unit, namespace):
    """Put a metric to CloudWatch"""
    try:
        logger.info(f"Publishing metric: {metric_name}={value} {unit}")
        cloudwatch_client.put_metric_data(
            Namespace=namespace,
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Value': value,
                    'Unit': unit,
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
    except ClientError as e:
        logger.error(f"Error publishing metric {metric_name}: {str(e)}")
        raise

def lambda_handler(event, context):
    """Main Lambda handler function"""
    logger.info("Starting EBS monitoring check...")
    logger.info(f"Event: {event}")
    
    # Initialize AWS clients
    try:
        ec2_client = boto3.client('ec2')
        cloudwatch_client = boto3.client('cloudwatch')
    except Exception as e:
        logger.error(f"Error initializing AWS clients: {str(e)}")
        raise
    
    # Get namespace from environment variable or use default
    namespace = os.environ.get('CLOUDWATCH_NAMESPACE', 'EBSMonitoring')
    logger.info(f"Using CloudWatch namespace: {namespace}")
    
    metrics = {}
    
    try:
        # Collect metrics
        unattached_count, total_size = get_unattached_volumes(ec2_client)
        metrics['unattached_volumes'] = unattached_count
        metrics['unattached_volumes_size'] = total_size
        
        unencrypted_volumes = get_unencrypted_volumes(ec2_client)
        metrics['unencrypted_volumes'] = unencrypted_volumes
        
        unencrypted_snapshots = get_unencrypted_snapshots(ec2_client)
        metrics['unencrypted_snapshots'] = unencrypted_snapshots
        
        # Put metrics to CloudWatch
        put_metric(cloudwatch_client, 'UnattachedVolumesCount', unattached_count, 'Count', namespace)
        put_metric(cloudwatch_client, 'UnattachedVolumesTotalSize', total_size, 'Gigabytes', namespace)
        put_metric(cloudwatch_client, 'UnencryptedVolumesCount', unencrypted_volumes, 'Count', namespace)
        put_metric(cloudwatch_client, 'UnencryptedSnapshotsCount', unencrypted_snapshots, 'Count', namespace)
        
        logger.info("Successfully published all metrics to CloudWatch")
        
        return {
            'statusCode': 200,
            'body': {
                'message': 'Metrics successfully published to CloudWatch',
                'metrics': metrics
            }
        }
    except Exception as e:
        logger.error(f"Error in Lambda execution: {str(e)}")
        return {
            'statusCode': 500,
            'body': {
                'message': f'Error collecting or publishing metrics: {str(e)}',
                'metrics': metrics
            }
        }