##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

output "rds_password" {
  description = "The password for the RDS instance"
  value       = random_password.randompass.result
  sensitive   = true
}

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

output "cluster_secrets_admin_user" {
  value = aws_secretsmanager_secret.dbuser.name
}

output "cluster_secrets_admin_password" {
  value = aws_secretsmanager_secret.randompass.name
}

output "cluster_secrets_credentials" {
  value = aws_secretsmanager_secret.rds.name
}