##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

terraform {
  # Write-only arguments (password_wo/password_wo_version) used by terraform-aws-modules/rds v7 require >= 1.11.1
  required_version = ">= 1.11.1"
  # Complete with required providers for the module
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
  }
}
