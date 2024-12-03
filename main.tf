##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#
locals {
  rds_port        = try(var.settings.port, 10001)
  master_username = try(var.settings.master_username, "admin")
  db_name         = try(var.settings.database_name, "cluster_db")
}

# Provisions RDS instance only if rds_provision=true
module "this" {
  depends_on = [
    random_password.randompass,
    aws_security_group.this
  ]
  source                              = "terraform-aws-modules/rds/aws"
  version                             = "6.10.0"
  identifier                          = "rds-db-${var.settings.name_prefix}-${local.system_name}"
  engine                              = var.settings.engine_type
  engine_version                      = var.settings.engine_version
  availability_zone                   = try(var.settings.availability_zones[0], null)
  instance_class                      = var.settings.instance_size
  allocated_storage                   = try(var.settings.storage_size, null)
  db_name                             = local.db_name
  username                            = local.master_username
  password                            = random_password.randompass.result
  manage_master_user_password         = false
  port                                = local.rds_port
  iam_database_authentication_enabled = try(var.settings.iam.database_authentication_enabled, false)
  vpc_security_group_ids              = local.security_group_ids
  maintenance_window                  = try(var.settings.maintenance_window, "Mon:00:00-Mon:01:00")
  backup_window                       = try(var.settings.backup.window, "01:00-03:00")
  create_monitoring_role              = try(var.settings.monitoring.create_role, false)
  create_db_subnet_group              = false
  db_subnet_group_name                = var.vpc.subnet_group
  family                              = try(var.settings.family, null)
  major_engine_version                = try(var.settings.major_engine_version, null)
  create_db_option_group              = try(var.settings.create_db_option_group, true)
  parameters                          = try(var.settings.parameters, [])
  options                             = try(var.settings.options, [])
  skip_final_snapshot                 = false
  snapshot_identifier                 = try(var.settings.restore_snapshot_identifier, null)
  final_snapshot_identifier_prefix    = "rds-db-${var.settings.name_prefix}-${local.system_name}-final-snap"
  deletion_protection                 = try(var.settings.deletion_protection, false)
  apply_immediately                   = try(var.settings.apply_immediately, true)
  auto_minor_version_upgrade          = try(var.settings.auto_minor_upgrade, false)
  tags                                = local.all_tags
}
