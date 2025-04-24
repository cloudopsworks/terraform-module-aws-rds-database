##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

##  YAML Input Format
# settings:
#   name_prefix: "mydb"
#   database_name: "mydb"
#   master_username: "admin"
#   engine_type: "postgresql" or "mysql" or "mariadb"  or "aurora-postgresql" or "aurora-mysql" or "mssql"
#   engine_version: "15.5"
#   availability_zones: ["us-east-1a", "us-east-1b"]
#   rds_port: 5432
#   instance_size: "db.r5.large"
#   storage_size: 100
#   maintenance_window: "Mon:00:00-Mon:01:00"
#   backup:
#     enabled: true | false
#     only_tag: true | false
#     window: "01:00-03:00"
#     retention_period: 7
#   monitoring:
#     create_role: true
#   storage:
#     encryption:
#       enabled: true
#       kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/alias/aws/rds"
#   apply_immediately: true
#   deletion_protection: true
#   family: "postgres15"
#   major_engine_version: "15"
#   create_db_option_group: true
#   parameters: []
#   options: []
#   restore_snapshot_identifier: "rds-db-mydb-0001-final-snap"
#   managed_password: true | false # If true, the password will be managed by AWS Secrets Manager, defaults to false
#   managed_password_rotation: true | false # If true, the password will be rotated automatically by AWS Secrets Manager, defaults to false
#   password_secret_kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" # KMS key for the password secret or Alias
#   rotation_lambda_name: "rds-rotation-lambda" # Name of the lambda function to rotate the password, required if managed_password_rotation is false
#   password_rotation_period: 90 # Rotation period in days for the password, defaults to 90days
#   rotation_duration: "1h" # Duration of the lambda function to rotate the password, defaults to 1h
#   hoop:
#     enabled: true | false
#     agent: hoop-agent-name
#     tags: ["tag1", "tag2"]
variable "settings" {
  description = "Settings for RDS instance"
  type        = any
  default     = {}
}

## YAML Input Format
# vpc:
#   vpc_id: "vpc-12345678901234"
#   subnet_group: "database_subnet_group_name"
#   subnet_ids:
#     - "subnet-abcdef123456789"
#     - "subnet-abcdef123456781"
#     - "subnet-abcdef123456782"
variable "vpc" {
  description = "VPC for RDS instance"
  type        = any
  default     = {}
}

## YAML Input Format
# security_groups:
#   create: true
#   name: sg-rds # Name of the security group if create = false
#   allow_cidrs:
#     - "1.2.3.4/32"
#     - "1.2.0.0/16"
#   allow_security_groups:
#     - "sg-name-123456"
#     - "sg-name-abcdef"
variable "security_groups" {
  description = "Security groups for RDS instance"
  type        = any
  default     = {}
}

variable "run_hoop" {
  description = "Run hoop with agent, be careful with this option, it will run the HOOP command in output in a null_resource"
  type        = bool
  default     = false
}