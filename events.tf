##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  default_event_categories = ["availability", "failover", "failure", "maintenance", "low storage"]
}

data "aws_sns_topic" "events" {
  count = try(var.settings.events.sns_topic_arn, "") != "" && try(var.settings.events.enabled, false) ? 1 : 0
  name = var.settings.events.sns_topic_name
}

resource "aws_db_event_subscription" "events" {
  count = try(var.settings.events.enabled, false) ? 1 : 0
  name  = "${local.db_identifier}-events"
  sns_topic = try(var.settings.events.sns_topic_arn, "") != "" ? var.settings.events.sns_topic_arn : data.aws_sns_topic.events[0].arn
  source_type = "db-instance"
  source_ids = [module.this.db_instance_identifier]
  event_categories = try(var.settings.events.categories, local.default_event_categories)
}