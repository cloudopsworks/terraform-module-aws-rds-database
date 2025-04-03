##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

# output "rds_password" {
#   description = "The password for the RDS instance"
#   value       = try(var.settings.managed_password_rotation, false) ? null : random_password.randompass[0].result
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

output "cluster_secrets_credentials" {
  value = try(var.settings.managed_password_rotation, false) ? data.aws_secretsmanager_secret.rds_managed[0].name : aws_secretsmanager_secret.rds[0].name
}
