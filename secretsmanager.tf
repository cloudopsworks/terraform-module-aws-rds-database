##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  rds_credentials = {
    username            = local.master_username
    password            = try(var.settings.managed_password_rotation, false) ? null : random_password.randompass[0].result
    engine              = module.this.db_instance_engine
    host                = module.this.db_instance_address
    port                = module.this.db_instance_port
    dbClusterIdentifier = module.this.db_instance_identifier
  }
}

# Secrets saving
resource "aws_secretsmanager_secret" "dbuser" {
  count      = try(var.settings.managed_password_rotation, false) ? 0 : 1
  depends_on = [module.this]
  name       = "${local.secret_store_path}/${var.settings.engine_type}/${module.this.db_instance_identifier}/${local.db_name}/master-username"
  tags       = local.all_tags
}

resource "aws_secretsmanager_secret_version" "dbuser" {
  count         = try(var.settings.managed_password_rotation, false) ? 0 : 1
  secret_id     = aws_secretsmanager_secret.dbuser[count.index].id
  secret_string = local.master_username
}

resource "aws_secretsmanager_secret" "randompass" {
  count      = try(var.settings.managed_password_rotation, false) ? 0 : 1
  depends_on = [module.this]
  name       = "${local.secret_store_path}/${var.settings.engine_type}/${module.this.db_instance_identifier}/${local.db_name}/master-password"
  tags       = local.all_tags
}

resource "aws_secretsmanager_secret_version" "randompass" {
  count         = try(var.settings.managed_password_rotation, false) ? 0 : 1
  secret_id     = aws_secretsmanager_secret.randompass[count.index].id
  secret_string = random_password.randompass[count.index].result
}

# Secrets saving
resource "aws_secretsmanager_secret" "rds" {
  count = try(var.settings.managed_password_rotation, false) ? 0 : 1
  name  = "${local.secret_store_path}/${var.settings.engine_type}/${module.this.db_instance_identifier}/${local.db_name}/master-rds-credentials"
  tags  = local.all_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  count         = try(var.settings.managed_password_rotation, false) ? 0 : 1
  secret_id     = aws_secretsmanager_secret.rds[count.index].id
  secret_string = jsonencode(local.rds_credentials)
}
