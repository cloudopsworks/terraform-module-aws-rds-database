##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  rds_credentials = {
    username             = local.master_username
    password             = local.generate_password ? random_password.randompass[0].result : null
    engine               = module.this.db_instance_engine
    host                 = module.this.db_instance_address
    port                 = module.this.db_instance_port
    dbname               = local.db_name
    dbInstanceIdentifier = module.this.db_instance_identifier
    sslmode              = "require"
  }
  # The AWS managed master secret is created by RDS itself. Its friendly name has to be read
  # back from the API: the last segment of its ARN carries the random suffix Secrets Manager
  # appends, so it is not usable as a name by consumers
  master_user_secret_name = one(data.aws_secretsmanager_secret.rds_managed[*].name)

  secret_name        = local.db_name != null ? format("%s/%s/%s/%s/master-rds-credentials", local.secret_store_path, var.settings.engine_type, module.this.db_instance_identifier, local.db_name) : null
  secret_description = local.db_name != null ? format("RDS Aurora Master credentials - %s - %s - %s - %s", local.master_username, var.settings.engine_type, module.this.db_instance_name, local.db_name) : null
}

data "aws_secretsmanager_secret" "rds_managed" {
  count = local.managed_password ? 1 : 0
  arn   = module.this.db_instance_master_user_secret_arn
}

# Secrets saving
resource "aws_secretsmanager_secret" "rds" {
  count       = local.create_secret ? 1 : 0
  name        = local.secret_name
  description = local.secret_description
  kms_key_id  = try(var.settings.password_secret_kms_key_id, null)
  tags        = local.all_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  count         = local.create_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rds[count.index].id
  secret_string = jsonencode(local.rds_credentials)
}

data "aws_lambda_function" "rotation_function" {
  count         = local.create_secret && try(var.settings.rotation_lambda_name, "") != "" ? 1 : 0
  function_name = var.settings.rotation_lambda_name
}

resource "aws_secretsmanager_secret_rotation" "user" {
  count               = local.create_secret && try(var.settings.rotation_lambda_name, "") != "" ? 1 : 0
  secret_id           = aws_secretsmanager_secret.rds[0].id
  rotation_lambda_arn = data.aws_lambda_function.rotation_function[count.index].arn

  rotation_rules {
    automatically_after_days = try(var.settings.password_rotation_period, 90)
    duration                 = try(var.settings.rotation_duration, "1h")
  }
}
