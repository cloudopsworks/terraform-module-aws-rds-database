##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  rds_credentials = {
    username            = local.master_username
    password            = random_password.randompass.result
    engine              = module.this.db_instance_engine
    host                = module.this.db_instance_endpoint
    port                = module.this.db_instance_port
    dbClusterIdentifier = module.this.db_instance_identifier
  }
}

# Secrets saving
resource "aws_secretsmanager_secret" "dbuser" {
  depends_on = [module.this]
  name       = "${local.secret_store_path}/${module.this.db_instance_identifier}/${var.settings.engine_type}/${local.db_name}/master_username"
  tags       = local.all_tags
}

resource "aws_secretsmanager_secret_version" "dbuser" {
  secret_id     = aws_secretsmanager_secret.dbuser.id
  secret_string = local.master_username
}

resource "aws_secretsmanager_secret" "randompass" {
  depends_on = [module.this]
  name       = "${local.secret_store_path}/${module.this.db_instance_identifier}/${var.settings.engine_type}/${local.db_name}/master_password"
  tags       = local.all_tags
}

resource "aws_secretsmanager_secret_version" "randompass" {
  secret_id     = aws_secretsmanager_secret.randompass.id
  secret_string = random_password.randompass.result
}

# Secrets saving
resource "aws_secretsmanager_secret" "rds" {
  name = "${local.secret_store_path}/${module.this.db_instance_identifier}/${var.settings.engine_type}/${local.db_name}/rds-credentials"
  tags = local.all_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id     = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode(local.rds_credentials)
}
