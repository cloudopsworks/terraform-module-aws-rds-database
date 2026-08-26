##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "aws_kms_key" "this" {
  count = (try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false) &&
    try(var.settings.encryption.kms_key_id, var.settings.storage.encryption.kms_key_id, "") == "" ? 1 : 0
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
    try(var.settings.encryption.kms_key_id, var.settings.storage.encryption.kms_key_id, "") == "" ? 1 : 0
  )
  target_key_id = aws_kms_key.this[0].key_id
  name          = format("alias/%s-key", local.db_identifier)
}