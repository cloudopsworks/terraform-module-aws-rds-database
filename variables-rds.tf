##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

##  YAML Input Format
# settings:
#   name: "mydb"                       # (Optional) The name of the RDS instance, if not provided it will be generated using name_prefix and system_name
#   name_prefix: "mydb"                # (Required) The name prefix of the RDS instance if name is not provided
#   database_name: "mydb"              # (Optional) The name of the database to create when the RDS instance is created, defaults to cluster_db.
#                                      #            Set explicitly to null to skip the initial database, which also disables the module managed Secrets Manager entry
#   master_username: "admin"           # (Optional) The master username for the RDS instance, defaults to admin
#   engine_type: "postgresql"          # (Required) The engine type of the RDS instance. Possible values: postgresql, mysql, mariadb, aurora-postgresql, aurora-mysql, mssql
#   engine_version: "15.5"             # (Required) The engine version of the RDS instance
#   availability_zones:                # (Optional) The availability zones for the RDS instance, only the first entry is used, defaults to null
#     - "us-east-1a"
#     - "us-east-1b"
#   port: 5432                         # (Optional) The port for the RDS instance, defaults to 10001
#   instance_size: "db.r5.large"       # (Required) The instance size for the RDS instance
#   storage_size: 100                  # (Required) The storage size for the RDS instance in GB
#   storage_max_size: 200              # (Optional) The maximum storage size for the RDS instance in GB, to enable autoextend
#   maintenance_window: "Mon:00:00-Mon:01:00" # (Optional) The maintenance window for the RDS instance, defaults to Mon:00:00-Mon:01:00
#   auto_minor_upgrade: false          # (Optional) If true, minor engine versions are upgraded automatically during the maintenance window, defaults to false. Alias: allow_upgrade
#   backup:                            # (Optional) The backup settings for the RDS instance
#     enabled: true                    # (Optional) If true, AWS Backup tagging will be enabled, defaults to false
#     only_tag: true                   # (Optional) If true, the instance is only tagged for an external AWS Backup plan, defaults to true
#     schedule: "daily"                # (Optional) The AWS Backup plan schedule tag value, defaults to daily. Only applies when enabled and only_tag are true
#     window: "01:00-03:00"            # (Optional) The backup window for the RDS instance, defaults to 01:00-03:00
#     retention_period: 7              # (Optional) The retention period for the backup in days, defaults to 7
#     copy_tags: true                  # (Optional) Fallback for copy_tags_to_snapshot when it is not set, defaults to true
#   monitoring:                        # (Optional) The monitoring settings for the RDS instance
#     enabled: true                    # (Optional) If true, the monitoring role will be created, defaults to false
#     interval: 60                     # (Optional) The monitoring interval in seconds, defaults to 0 (disabled). Possible values: 0, 1, 5, 10, 15, 30, 60
#   cloudwatch:                        # (Optional) The cloudwatch settings for the RDS instance
#     enabled: true                    # (Optional) If true, the cloudwatch log group will be created, defaults to false
#     exported_logs:                   # (Optional) The logs to export to cloudwatch. Possible values: alert, audit, error, general, listener, slowquery, trace, postgresql, upgrade
#       - "alert"                      #            Defaults to [postgresql, upgrade] for postgres engines, [audit, error] otherwise
#       - "audit"
#       - "error"
#     skip_destroy: true               # (Optional) If true, the cloudwatch log group will not be destroyed, defaults to false
#     retention_in_days: 7             # (Optional) The retention period for the cloudwatch log group in days, defaults to 7
#     kms_key_id: "arn:aws:kms..."     # (Optional) The KMS key ARN used to encrypt the cloudwatch log group, defaults to null (AWS managed)
#     class: STANDARD                  # (Optional) The class for the cloudwatch log group. Possible values: STANDARD, INFREQUENT_ACCESS. Defaults to STANDARD
#   storage:                           # (Optional) The storage settings for the RDS instance
#     type: gp3                        # (Optional) The storage type for the RDS instance. Possible values: gp2, gp3, io1, io2. Defaults to gp3
#     throughput: 100                  # (Optional) The throughput for the storage in MB/s, only for gp3
#     iops: 3000                       # (Optional) The IOPS for the storage, only for io1, io2 and gp3
#     encryption:                      # (Optional) The encryption settings for the storage
#       enabled: true                  # (Optional) If true, the storage will be encrypted, defaults to false
#       kms_key_id: "arn:aws:kms..."   # (Optional) The KMS key ID for the storage encryption
#   performance_insights:              # (Optional) The performance insights settings for the RDS instance. Alias: performance
#     enabled: true                    # (Optional) If true, the performance insights will be enabled, defaults to false
#     kms_key_id: "arn:aws:kms..."     # (Optional) The KMS key ID for the performance insights
#     retention_period: 15             # (Optional) The retention period for the performance insights in days, defaults to null (7 days on AWS). Possible values: 7, 731 or any multiple of 31
#   apply_immediately: true            # (Optional) If true, the changes will be applied immediately, defaults to true
#   deletion_protection: true          # (Optional) If true, the deletion protection will be enabled, defaults to false
#   family: "postgres15"               # (Required) The family for the RDS instance
#   major_engine_version: "15"         # (Required) The major engine version for the RDS instance
#   create_db_option_group: true       # (Optional) If true, the DB option group will be created, defaults to true
#   copy_tags_to_snapshot: true        # (Optional) If true, the tags will be copied to the snapshot, defaults to true
#   parameters: []                     # (Optional) The parameters for the RDS instance, defaults to []
#   options: []                        # (Optional) The options for the RDS instance, defaults to []
#   restore_snapshot_identifier: "..." # (Optional) The snapshot identifier to restore the RDS instance from. Alias: recovery.snapshot_identifier
#   recovery:                          # (Optional) Recovery settings, alternative location for the restore snapshot identifier
#     snapshot_identifier: "..."       # (Optional) The snapshot identifier to restore the RDS instance from, used when restore_snapshot_identifier is not set
#   managed_password: true             # (Optional) If true, the password will be managed by AWS Secrets Manager, defaults to false.
#                                      #            When false, the module generates the password and stores it on its own Secrets Manager secret,
#                                      #            delivering it to RDS through the write-only arguments password_wo/password_wo_version
#   managed_password_rotation: true    # (Optional) If true, the password will be rotated automatically by AWS Secrets Manager, defaults to false. Only applies when managed_password is true
#   password_secret_kms_key_id: "..."  # (Optional) The KMS key ID for the password secret or Alias
#   rotation_lambda_name: "..."        # (Optional) The name of an existing lambda function used to rotate the module managed secret, only applies when managed_password is false
#   password_rotation_period: 90       # (Optional) The rotation period in days, defaults to 90. Drives the Secrets Manager rotation when managed_password_rotation is true,
#                                      #            and the regeneration cadence of the module generated password otherwise
#   rotation_duration: "1h"            # (Optional) The duration window of the rotation, defaults to 1h
#   iam:                               # (Optional) The IAM settings for the RDS instance
#     database_authentication_enabled: true # (Optional) If true, the database authentication will be enabled, defaults to true
#   hoop:                              # (Optional) Hoop connection output settings for terraform-module-hoop-connection
#     enabled: true                    # (Optional) If true, the hoop settings will be enabled, defaults to false
#     agent_id: "hoop-agent-uuid"      # (Required when enabled) Hoop agent UUID
#     community: true                  # (Optional) Use community secret prefix (_aws:) vs enterprise (_envs/aws#); default: true
#     import: false                    # (Optional) Import existing Hoop connection; default: false
#     tags: {key: "value"}             # (Optional) Tags map for Hoop connection
#     access_control: ["group"]        # (Optional) Access control groups for Hoop connection
#   events:                            # (Optional) The events settings for the RDS instance
#     enabled: true                    # (Optional) If true, the events settings will be enabled, defaults to false
#     sns_topic_arn: "arn:aws:sns..."  # (Optional) The SNS topic ARN for the events
#     sns_topic_name: "my-sns-topic"   # (Optional) The SNS topic name for the events, required if sns_topic_arn is not provided
#     categories: ["availability", ...] # (Optional) The categories for the events, defaults to [availability, failover, failure, maintenance, low storage].
#                                      #            Possible values: availability, deletion, failover, failure, low storage, maintenance, notification, read replica, recovery, restore, security, storage
variable "settings" {
  description = "Settings for RDS instance"
  type        = any
  default     = {}
}

## YAML Input Format
# vpc:
#   vpc_id: "vpc-12345678901234"       # (Required) The VPC ID where the RDS security group is created
#   subnet_group: "database_sg_name"   # (Required) The name of the existing database subnet group, the module does not create one
#   subnet_ids:                        # (Optional) The list of subnet IDs, populated by the Terragrunt VPC dependency, not consumed directly by the module
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
#   create: true                       # (Optional) If true, the security group will be created, defaults to false
#   name: sg-rds                       # (Required if create=false) The name of the security group to use if create=false
#   allow_cidrs:                       # (Optional) The list of CIDR blocks to allow access to the RDS instance
#     - "1.2.3.4/32"
#     - "1.2.0.0/16"
#   allow_security_groups:             # (Optional) The list of security group names to allow access to the RDS instance
#     - "sg-name-123456"
#     - "sg-name-abcdef"
variable "security_groups" {
  description = "Security groups for RDS instance"
  type        = any
  default     = {}
}

