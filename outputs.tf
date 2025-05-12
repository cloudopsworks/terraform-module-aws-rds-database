##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

# output "rds_password" {
#   description = "The password for the RDS instance"
#   value       = try(var.settings.managed_password, false) ? null : random_password.randompass[0].result
#   sensitive   = true
# }
# RDS Password will not be exposed by any means

output "rds_security_group_ids" {
  value = local.security_group_ids
}

output "rds_instance_arn" {
  value = module.this.db_instance_arn
}

output "rds_instance_address" {
  value = module.this.db_instance_address
}

output "rds_instance_endpoint" {
  value = module.this.db_instance_endpoint
}

output "rds_instance_hosted_zone_id" {
  value = module.this.db_instance_hosted_zone_id
}

output "rds_instance_port" {
  value = module.this.db_instance_port
}

output "rds_instance_username" {
  value     = module.this.db_instance_username
  sensitive = true
}

output "rds_secrets_credentials" {
  value = try(var.settings.managed_password, false) ? local.master_user_secret_name : aws_secretsmanager_secret.rds[0].name
}

output "rds_secrets_credentials_arn" {
  value = try(var.settings.managed_password, false) ? module.this.db_instance_master_user_secret_arn : aws_secretsmanager_secret.rds[0].arn
}

output "rds_enhanced_monitoring_iam_role_arn" {
  value = module.this.enhanced_monitoring_iam_role_arn
}

output "rds_enhanced_monitoring_iam_role_name" {
  value = module.this.enhanced_monitoring_iam_role_name
}