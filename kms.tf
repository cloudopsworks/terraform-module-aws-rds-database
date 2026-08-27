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
  encryption_enabled            = try(var.settings.encryption.enabled, var.settings.storage.encryption.enabled, false)
  create_kms_key                = local.encryption_enabled && local.encryption_key_id == "" && local.encryption_key_alias_raw == ""
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# Key policy for the module managed key. The AWS default key policy only grants the account
# root, which is not enough: CloudWatch Logs reaches the key as a service principal and never
# through IAM, so without an explicit grant the encrypted log group cannot be written.
data "aws_iam_policy_document" "kms" {
  count = local.create_kms_key ? 1 : 0

  # Keeps the key manageable through IAM. Dropping this statement orphans the key
  statement {
    sid    = "EnableRootAccountPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Storage encryption and the Performance Insights readers both reach the key through the RDS
  # service, so a single ViaService statement covers them. Performance Insights creates its own
  # grants, which is why kms:CreateGrant is included
  statement {
    sid    = "AllowAccessThroughRDS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["rds.${data.aws_region.current.region}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Scoped to the log groups the upstream module creates for this instance,
  # /aws/rds/instance/<identifier>/<log type>
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/rds/instance/${local.db_identifier}/*"]
    }
  }
}

resource "aws_kms_key" "this" {
  count                   = local.create_kms_key ? 1 : 0
  description             = "KMS key for RDS encryption for ${local.db_identifier}"
  policy                  = data.aws_iam_policy_document.kms[0].json
  deletion_window_in_days = try(var.settings.storage.encryption.deletion_window, 30)
  rotation_period_in_days = try(var.settings.storage.encryption.rotation_period, 90)
  enable_key_rotation     = try(var.settings.storage.encryption.rotation_enabled, true)
  multi_region            = try(var.settings.storage.encryption.multi_region, false)
  is_enabled              = try(var.settings.storage.encryption.enabled, true)
  tags                    = local.all_tags
}

resource "aws_kms_alias" "this" {
  count         = local.create_kms_key ? 1 : 0
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
