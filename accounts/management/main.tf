########### TERRAFORM VERSION ###########
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

########### BACKEND ###########
  backend "s3" {
    bucket         = "auto-rmf-terraform-state"
    key            = "management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

########### PROVIDER ###########
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AUTO-RMF"
      ManagedBy   = "Terraform"
      Environment = "Production"
      Account     = "Management"
    }
  }
}

########### LOCAL VARIABLES ###########
locals {
  cloudtrail_bucket_name = "auto-rmf-cloudtrail-logs"
}

##############################################################################
##############################################################################

########### AWS ORGANIZATIONS - DATA SOURCE ###########
data "aws_organizations_organization" "main" {}

########### TERRAFORM STATE INFRASTRUCTURE - DATA SOURCES ###########
data "aws_s3_bucket" "terraform_state" {
  bucket = "auto-rmf-terraform-state"
}

data "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-state-lock"
}

##############################################################################
##############################################################################

########### DELEGATED ADMINISTRATOR - GUARDDUTY ###########
resource "aws_organizations_delegated_administrator" "guardduty" {
  account_id        = var.security_account_id
  service_principal = "guardduty.amazonaws.com"
}

########### DELEGATED ADMINISTRATOR - SECURITY HUB ###########
resource "aws_organizations_delegated_administrator" "securityhub" {
  account_id        = var.security_account_id
  service_principal = "securityhub.amazonaws.com"
}

########### DELEGATED ADMINISTRATOR - CONFIG ###########
resource "aws_organizations_delegated_administrator" "config" {
  account_id        = var.security_account_id
  service_principal = "config.amazonaws.com"
}

##############################################################################
##############################################################################

########### ORGANIZATION CLOUDTRAIL ###########
resource "aws_cloudtrail" "organization_trail" {
  name                          = "auto-rmf-org-trail"
  s3_bucket_name                = local.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}

##############################################################################
##############################################################################

########### SERVICE CONTROL POLICY - REQUIRE ENCRYPTION ###########
resource "aws_organizations_policy" "require_encryption" {
  name        = "RequireEncryption"
  description = "Require encryption for S3 and EBS"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnencryptedS3Upload"
        Effect   = "Deny"
        Action   = "s3:PutObject"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["AES256", "aws:kms"]
          }
        }
      },
      {
        Sid      = "DenyUnencryptedEBSVolumes"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:volume/*"
        Condition = {
          Bool = {
            "ec2:Encrypted" = "false"
          }
        }
      }
    ]
  })
}

########### SCP ATTACHMENT - REQUIRE ENCRYPTION ###########
resource "aws_organizations_policy_attachment" "require_encryption" {
  policy_id = aws_organizations_policy.require_encryption.id
  target_id = data.aws_organizations_organization.main.roots[0].id
}

##############################################################################
##############################################################################

########### BUDGET ALERTS ###########
resource "aws_budgets_budget" "monthly" {
  name              = "auto-rmf-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "50"
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

##############################################################################
##############################################################################

########### SECURITY SERVICES MODULE ###########
module "security_services" {
  source = "../../modules/security-services"

  aws_region = var.aws_region
  account_id = var.management_account_id
}

########### COMPLIANCE BASELINE MODULE ###########
module "compliance_baseline" {
  source = "../../modules/compliance-baseline"

  depends_on = [module.security_services]
  aws_region = var.aws_region
  account_id = var.management_account_id
}
