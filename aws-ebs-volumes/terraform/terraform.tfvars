aws_region = "us-east-1"
project    = "ebs-volumes"
environment = "prod"

volumes = {
  "app-data" = {
    size              = 10
    type             = "gp3"
    availability_zone = "us-east-1a"
    encrypted        = true
    description      = "Application data volume"
    iops            = 3000
    throughput      = 125
  },
  "db-data" = {
    size              = 20
    type             = "gp3"
    availability_zone = "us-east-1b"
    encrypted        = true
    description      = "Database data volume"
    iops            = 3000
    throughput      = 125
  }
}

enable_backup = true 