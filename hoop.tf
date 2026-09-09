##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  hoop_enabled               = try(var.settings.hoop.enabled, false)
  hoop_secret_prefix         = try(var.settings.hoop.community, true) ? "_aws" : "_envs/aws"
  hoop_secret_sep            = try(var.settings.hoop.community, true) ? ":" : "#"
  hoop_is_postgres           = strcontains(try(var.settings.engine_type, ""), "postgres")
  hoop_is_managed            = try(var.settings.managed_password, false)
  hoop_managed_secret_name   = local.master_user_secret_name != null ? local.master_user_secret_name : ""
  hoop_unmanaged_secret_name = try(aws_secretsmanager_secret.rds[0].name, "")
}

output "hoop_connections" {
  description = "Hoop connection definitions to be consumed by terraform-module-hoop-connection, null when settings.hoop.enabled is false"
  value = local.hoop_enabled ? {
    "owner" = {
      name           = "${local.db_identifier}-ow"
      agent_id       = var.settings.hoop.agent_id
      type           = "database"
      subtype        = local.hoop_is_postgres ? "postgres" : "mysql"
      tags           = try(var.settings.hoop.tags, {})
      access_control = toset(try(var.settings.hoop.access_control, []))
      access_modes   = { connect = "enabled", exec = "enabled", runbooks = "enabled", schema = "enabled" }
      import         = try(var.settings.hoop.import, false)
      secrets = local.hoop_is_postgres && local.hoop_is_managed ? {
        "envvar:HOST"    = module.this.db_instance_address
        "envvar:PORT"    = tostring(module.this.db_instance_port)
        "envvar:USER"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"      = local.db_name
        "envvar:SSLMODE" = "prefer"
        } : local.hoop_is_postgres && !local.hoop_is_managed ? {
        "envvar:HOST"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}host"
        "envvar:PORT"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}port"
        "envvar:USER"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS"    = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"      = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}dbname"
        "envvar:SSLMODE" = "prefer"
        } : local.hoop_is_managed ? {
        "envvar:HOST" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}host"
        "envvar:PORT" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}port"
        "envvar:USER" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"   = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_managed_secret_name}${local.hoop_secret_sep}dbname"
        } : {
        "envvar:HOST" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}host"
        "envvar:PORT" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}port"
        "envvar:USER" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}username"
        "envvar:PASS" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}password"
        "envvar:DB"   = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${local.hoop_unmanaged_secret_name}${local.hoop_secret_sep}dbname"
      }
    }
  } : null
  precondition {
    condition     = !local.hoop_enabled || try(var.settings.hoop.agent_id, "") != ""
    error_message = "settings.hoop.agent_id must be set (as a Hoop agent UUID) when settings.hoop.enabled is true."
  }
}
