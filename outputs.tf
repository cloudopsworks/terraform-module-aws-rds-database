##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# output "rds_password" {
#   description = "The password for the RDS instance"
#   value       = try(var.settings.managed_password, false) ? null : random_password.randompass[0].result
#   sensitive   = true
# }
# RDS Password will not be exposed by any means

output "rds_security_group_ids" {
  description = "The list of security group IDs attached to the RDS instance, created by the module or looked up from the existing security group"
  value       = local.security_group_ids
}

output "rds_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = module.this.db_instance_identifier
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.this.db_instance_arn
}

output "rds_instance_address" {
  description = "The hostname of the RDS instance, without the port"
  value       = module.this.db_instance_address
}

output "rds_instance_endpoint" {
  description = "The connection endpoint of the RDS instance, in host:port format"
  value       = module.this.db_instance_endpoint
}

output "rds_instance_hosted_zone_id" {
  description = "The Route53 hosted zone ID of the RDS instance, to build alias records"
  value       = module.this.db_instance_hosted_zone_id
}

output "rds_instance_port" {
  description = "The port the RDS instance is listening on"
  value       = module.this.db_instance_port
}

output "rds_instance_username" {
  description = "The master username of the RDS instance"
  value       = module.this.db_instance_username
  sensitive   = true
}

output "rds_secrets_credentials" {
  description = "The name of the Secrets Manager secret holding the master credentials, AWS managed when settings.managed_password is true, module managed otherwise"
  value       = try(var.settings.managed_password, false) ? local.master_user_secret_name : aws_secretsmanager_secret.rds[0].name
}

output "rds_secrets_credentials_arn" {
  description = "The ARN of the Secrets Manager secret holding the master credentials, AWS managed when settings.managed_password is true, module managed otherwise"
  value       = try(var.settings.managed_password, false) ? module.this.db_instance_master_user_secret_arn : aws_secretsmanager_secret.rds[0].arn
}

output "rds_enhanced_monitoring_iam_role_arn" {
  description = "The ARN of the enhanced monitoring IAM role, null when settings.monitoring.enabled is false"
  value       = module.this.enhanced_monitoring_iam_role_arn
}

output "rds_enhanced_monitoring_iam_role_name" {
  description = "The name of the enhanced monitoring IAM role, null when settings.monitoring.enabled is false"
  value       = module.this.enhanced_monitoring_iam_role_name
}