##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
locals {
  encryption_key_id             = try(var.settings.encryption.kms_key_id, var.settings.storage.encryption.kms_key_id, "")
  encryption_key_alias_raw      = try(var.settings.encryption.kms_key_alias, var.settings.storage.encryption.kms_key_alias, "")
  encryption_key_alias          = startswith(local.encryption_key_alias_raw, "alias/") ? local.encryption_key_alias_raw : format("alias/%s", local.encryption_key_alias_raw)
  cw_encryption_key_id          = try(var.settings.cloudwatch.kms_key_id, "")
  cw_encryption_key_alias_raw   = try(var.settings.cloudwatch.kms_key_alias, "")
  cw_encryption_key_alias       = startswith(local.cw_encryption_key_alias_raw, "alias/") ? local.cw_encryption_key_alias_raw : format("alias/%s", local.cw_encryption_key_alias_raw)
  perf_encryption_key_id        = try(var.settings.performance_insights.kms_key_id, var.settings.performance.kms_key_id, "")
  perf_encryption_key_alias_raw = try(var.settings.performance_insights.kms_key_alias, var.settings.performance.kms_key_alias, "")
  perf_encryption_key_alias     = startswith(local.perf_encryption_key_alias_raw, "alias/") ? local.perf_encryption_key_alias_raw : format("alias/%s", local.perf_encryption_key_alias_raw)
}

resource "aws_kms_key" "this" {
  count = (try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false) &&
    local.encryption_key_id == "" &&
    local.encryption_key_alias_raw == "" ? 1 : 0
  )
  description             = "KMS key for RDS encryption for ${local.db_identifier}"
  deletion_window_in_days = try(var.settings.storage.encryption.deletion_window, 30)
  rotation_period_in_days = try(var.settings.storage.encryption.rotation_period, 90)
  enable_key_rotation     = try(var.settings.storage.encryption.rotation_enabled, true)
  multi_region            = try(var.settings.storage.encryption.multi_region, false)
  is_enabled              = try(var.settings.storage.encryption.enabled, true)
  tags                    = local.all_tags
}

resource "aws_kms_alias" "this" {
  count = (try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false) &&
    local.encryption_key_id == "" &&
    local.encryption_key_alias_raw == "" ? 1 : 0
  )
  target_key_id = aws_kms_key.this[0].key_id
  name          = format("alias/%s-key", local.db_identifier)
}

data "aws_kms_key" "this" {
  count = (try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false) &&
    local.encryption_key_id != "" ? 1 : 0
  )
  key_id = local.encryption_key_id
}

data "aws_kms_alias" "this" {
  count = (try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false) &&
    local.encryption_key_id == "" &&
    local.encryption_key_alias_raw != "" ? 1 : 0
  )
  name = local.encryption_key_alias
}

data "aws_kms_key" "cw" {
  count = (try(var.settings.cloudwatch.enabled, false) &&
    local.cw_encryption_key_id != "" ? 1 : 0
  )
  key_id = local.cw_encryption_key_id
}

data "aws_kms_alias" "cw" {
  count = (try(var.settings.cloudwatch.enabled, false) &&
    local.cw_encryption_key_id == "" &&
    local.cw_encryption_key_alias_raw != "" ? 1 : 0
  )
  name = local.cw_encryption_key_alias
}

data "aws_kms_key" "perf" {
  count = (try(var.settings.performance_insights.enabled, var.settings.performance.enabled, false) &&
    local.perf_encryption_key_id != "" ? 1 : 0
  )
  key_id = local.perf_encryption_key_id
}

data "aws_kms_alias" "perf" {
  count = (try(var.settings.performance_insights.enabled, var.settings.performance.enabled, false) &&
    local.perf_encryption_key_id == "" &&
    local.perf_encryption_key_alias_raw != "" ? 1 : 0
  )
  name = local.perf_encryption_key_alias
}
