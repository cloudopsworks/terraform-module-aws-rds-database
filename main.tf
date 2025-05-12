##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  rds_port              = try(var.settings.port, 10001)
  master_username       = try(var.settings.master_username, "admin")
  db_name               = try(var.settings.database_name, "cluster_db")
  db_identifier         = "rds-db-${var.settings.name_prefix}-${local.system_name}"
  default_exported_logs = strcontains(var.settings.engine_type, "postgres") ? ["postgresql", "upgrade"] : ["alert", "audit", "error"]
}

resource "random_string" "final_snapshot" {
  length  = 10
  special = false
  upper   = false
  lower   = true
  numeric = true
}

# Provisions RDS instance only if rds_provision=true
module "this" {
  depends_on = [
    random_password.randompass,
    aws_security_group.this
  ]
  source                                                 = "terraform-aws-modules/rds/aws"
  version                                                = "~> 6.11"
  identifier                                             = local.db_identifier
  engine                                                 = var.settings.engine_type
  engine_version                                         = var.settings.engine_version
  availability_zone                                      = try(var.settings.availability_zones[0], null)
  instance_class                                         = var.settings.instance_size
  allocated_storage                                      = try(var.settings.storage_size, null)
  port                                                   = local.rds_port
  db_name                                                = local.db_name
  username                                               = local.master_username
  password                                               = try(var.settings.managed_password, false) ? null : random_password.randompass[0].result
  manage_master_user_password                            = try(var.settings.managed_password, false)
  manage_master_user_password_rotation                   = try(var.settings.managed_password_rotation, false)
  master_user_secret_kms_key_id                          = try(var.settings.managed_password, false) ? try(var.settings.password_secret_kms_key_id, null) : null
  master_user_password_rotation_automatically_after_days = try(var.settings.managed_password_rotation, false) ? try(var.settings.password_rotation_period, 90) : null
  master_user_password_rotation_duration                 = try(var.settings.managed_password_rotation, false) ? try(var.settings.rotation_duration, "1h") : null
  iam_database_authentication_enabled                    = try(var.settings.iam.database_authentication_enabled, false)
  vpc_security_group_ids                                 = local.security_group_ids
  maintenance_window                                     = try(var.settings.maintenance_window, "Mon:00:00-Mon:01:00")
  backup_window                                          = try(var.settings.backup.window, "01:00-03:00")
  backup_retention_period                                = try(var.settings.backup.reteniton_period, 7)
  create_monitoring_role                                 = try(var.settings.monitoring.enabled, false)
  monitoring_interval                                    = try(var.settings.monitoring.interval, null)
  monitoring_role_description                            = "Detailed Monitoring Role for DB ${local.db_identifier}"
  monitoring_role_name                                   = format("%s-monitoring-role", local.db_identifier)
  create_db_subnet_group                                 = false
  db_subnet_group_name                                   = var.vpc.subnet_group
  family                                                 = try(var.settings.family, null)
  major_engine_version                                   = try(var.settings.major_engine_version, null)
  create_db_option_group                                 = try(var.settings.create_db_option_group, true)
  parameters                                             = try(var.settings.parameters, [])
  options                                                = try(var.settings.options, [])
  skip_final_snapshot                                    = false
  snapshot_identifier                                    = try(var.settings.restore_snapshot_identifier, null)
  final_snapshot_identifier_prefix                       = format("%s-final-snap-%s", local.db_identifier, random_string.final_snapshot.result)
  copy_tags_to_snapshot                                  = try(var.settings.copy_tags_to_snapshot, true)
  deletion_protection                                    = try(var.settings.deletion_protection, false)
  apply_immediately                                      = try(var.settings.apply_immediately, true)
  auto_minor_version_upgrade                             = try(var.settings.auto_minor_upgrade, false)
  storage_encrypted                                      = try(var.settings.storage.encryption.enabled, false)
  kms_key_id                                             = try(var.settings.storage.encryption.kms_key_id, null)
  create_cloudwatch_log_group                            = try(var.settings.cloudwatch.enabled, false)
  enabled_cloudwatch_logs_exports                        = try(var.settings.cloudwatch.exported_logs, local.default_exported_logs)
  cloudwatch_log_group_skip_destroy                      = try(var.settings.cloudwatch.skip_destroy, false)
  cloudwatch_log_group_kms_key_id                        = try(var.settings.cloudwatch.kms_key_id, null)
  cloudwatch_log_group_retention_in_days                 = try(var.settings.cloudwatch.retention_in_days, 7)
  cloudwatch_log_group_class                             = try(var.settings.cloudwatch.class, null)
  tags                                                   = merge(local.all_tags, local.backup_tags)
}
