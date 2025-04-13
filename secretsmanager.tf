##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  rds_credentials = {
    username             = local.master_username
    password             = try(var.settings.managed_password_rotation, false) ? null : random_password.randompass[0].result
    engine               = module.this.db_instance_engine
    host                 = module.this.db_instance_address
    port                 = module.this.db_instance_port
    dbname               = local.db_name
    dbInstanceIdentifier = module.this.db_instance_identifier
  }
}

# Secrets saving
resource "aws_secretsmanager_secret" "rds" {
  count       = try(var.settings.managed_password_rotation, false) ? 0 : 1
  name        = "${local.secret_store_path}/${var.settings.engine_type}/${module.this.db_instance_identifier}/${local.db_name}/master-rds-credentials"
  description = "RDS Aurora Master credentials - ${local.master_username} - ${var.settings.engine_type} - ${module.this.db_instance_name} - ${local.db_name}"
  kms_key_id  = try(var.settings.password_secret_kms_key_id, null)
  tags        = local.all_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  count         = try(var.settings.managed_password_rotation, false) ? 0 : 1
  secret_id     = aws_secretsmanager_secret.rds[count.index].id
  secret_string = jsonencode(local.rds_credentials)
}

data "aws_lambda_function" "rotation_function" {
  count         = try(var.settings.managed_password_rotation, false) == false && try(var.settings.rotation_lambda_name, "") != "" ? 1 : 0
  function_name = var.settings.rotation_lambda_name
}

resource "aws_secretsmanager_secret_rotation" "user" {
  count               = try(var.settings.managed_password_rotation, false) == false && try(var.settings.rotation_lambda_name, "") != "" ? 1 : 0
  secret_id           = aws_secretsmanager_secret.rds[0].id
  rotation_lambda_arn = data.aws_lambda_function.rotation_function[count.index].arn

  rotation_rules {
    automatically_after_days = try(var.settings.password_rotation_period, 90)
    duration                 = try(var.settings.rotation_duration, "1h")
  }
}
