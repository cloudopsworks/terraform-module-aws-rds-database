##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
locals {
  rds_port              = try(var.settings.port, 10001)
  master_username       = try(var.settings.master_username, "admin")
  db_name               = try(var.settings.database_name, "cluster_db")
  db_identifier         = try(var.settings.name, "") != "" ? var.settings.name : "rds-db-${var.settings.name_prefix}-${local.system_name}"
  default_exported_logs = strcontains(var.settings.engine_type, "postgres") ? ["postgresql", "upgrade"] : ["audit", "error"]
  snapshot_identifier   = try(var.settings.restore_snapshot_identifier, var.settings.recovery.snapshot_identifier, null)
  managed_password      = try(var.settings.managed_password, false)
  # The module generates and stores the master password only for fresh instances that do not
  # delegate the secret to AWS; a snapshot restore carries the master password of the snapshot.
  generate_password = !local.managed_password && local.snapshot_identifier == null
  # settings.database_name may be explicitly null, meaning no initial database is created.
  # The module managed secret is keyed on the database name, so the whole Secrets Manager
  # path is disabled in that case.
  create_secret = local.generate_password && local.db_name != null
  # RDS only picks up password_wo when password_wo_version changes, so the version is derived
  # from the password itself. Any regeneration reaches the instance, whether it comes from the
  # scheduled rotation or from a change to the generator, and the stored secret never drifts
  # away from the live credentials
  password_wo_version = local.generate_password ? parseint(substr(sha256(random_password.randompass[0].result), 0, 8), 16) : null
}

# Provisions RDS instance only if rds_provision=true
module "this" {
  depends_on = [
    random_password.randompass,
    aws_security_group.this
  ]
  source                                                 = "terraform-aws-modules/rds/aws"
  version                                                = "~> 7.0"
  identifier                                             = local.db_identifier
  engine                                                 = var.settings.engine_type
  engine_version                                         = var.settings.engine_version
  availability_zone                                      = try(var.settings.availability_zones[0], null)
  instance_class                                         = var.settings.instance_size
  allocated_storage                                      = try(var.settings.storage_size, null)
  max_allocated_storage                                  = try(var.settings.storage_max_size, null)
  port                                                   = local.rds_port
  db_name                                                = local.db_name
  username                                               = local.master_username
  password_wo                                            = local.generate_password ? random_password.randompass[0].result : null
  password_wo_version                                    = local.password_wo_version
  manage_master_user_password                            = local.managed_password
  manage_master_user_password_rotation                   = try(var.settings.managed_password_rotation, false)
  master_user_secret_kms_key_id                          = local.managed_password ? try(var.settings.password_secret_kms_key_id, null) : null
  master_user_password_rotation_automatically_after_days = try(var.settings.managed_password_rotation, false) ? try(var.settings.password_rotation_period, 90) : null
  master_user_password_rotation_duration                 = try(var.settings.managed_password_rotation, false) ? try(var.settings.rotation_duration, "1h") : null
  iam_database_authentication_enabled                    = try(var.settings.iam.database_authentication_enabled, true)
  vpc_security_group_ids                                 = local.security_group_ids
  maintenance_window                                     = try(var.settings.maintenance_window, "Mon:00:00-Mon:01:00")
  backup_window                                          = try(var.settings.backup.window, "01:00-03:00")
  backup_retention_period                                = try(var.settings.backup.retention_period, 7)
  create_monitoring_role                                 = try(var.settings.monitoring.enabled, false)
  monitoring_interval                                    = try(var.settings.monitoring.interval, 0)
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
  snapshot_identifier                                    = local.snapshot_identifier
  final_snapshot_identifier_prefix                       = format("final-snap%s", try(var.settings.final_snapshot_generation, ""))
  copy_tags_to_snapshot                                  = try(var.settings.copy_tags_to_snapshot, var.settings.backup.copy_tags, true)
  deletion_protection                                    = try(var.settings.deletion_protection, false)
  apply_immediately                                      = try(var.settings.apply_immediately, true)
  auto_minor_version_upgrade                             = try(var.settings.auto_minor_upgrade, var.settings.allow_upgrade, false)
  storage_encrypted                                      = try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false)
  storage_type                                           = try(var.settings.storage.type, "gp3")
  storage_throughput                                     = try(var.settings.storage.throughput, null)
  iops                                                   = try(var.settings.storage.iops, null)
  kms_key_id                                             = try(coalesce(one(data.aws_kms_alias.this[*].target_key_arn), one(aws_kms_key.this[*].arn), one(data.aws_kms_key.this[*].arn)), null)
  create_cloudwatch_log_group                            = try(var.settings.cloudwatch.enabled, false)
  enabled_cloudwatch_logs_exports                        = try(var.settings.cloudwatch.exported_logs, local.default_exported_logs)
  cloudwatch_log_group_skip_destroy                      = try(var.settings.cloudwatch.skip_destroy, false)
  cloudwatch_log_group_kms_key_id                        = try(coalesce(one(data.aws_kms_key.cw[*].arn), one(data.aws_kms_alias.cw[*].target_key_arn), one(aws_kms_key.this[*].arn)), null)
  cloudwatch_log_group_retention_in_days                 = try(var.settings.cloudwatch.retention_in_days, 7)
  cloudwatch_log_group_class                             = try(var.settings.cloudwatch.class, null)
  performance_insights_enabled                           = try(var.settings.performance_insights.enabled, var.settings.performance.enabled, false)
  performance_insights_kms_key_id                        = try(coalesce(one(data.aws_kms_alias.perf[*].target_key_arn), one(data.aws_kms_key.perf[*].arn), one(aws_kms_key.this[*].arn)), null)
  performance_insights_retention_period                  = try(var.settings.performance_insights.retention_period, var.settings.performance.retention_period, null)
  tags                                                   = merge(local.all_tags, local.backup_tags)
}
