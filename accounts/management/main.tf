#################################
########## References ###########
#################################

# terraform version
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

# management account backend reference
  backend "s3" {
    bucket         = "auto-rmf-terraform-state"
    key            = "management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# management account provider 
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

# management account local variables
locals {
  aws_region             = "us-east-1"
  alert_email            = "cloudsecgrc@gmail.com"
  management_account_id  = "995761092254"
  security_account_id    = "918595517273"
  cloudtrail_bucket_name = "auto-rmf-cloudtrail-logs"
}

###############################################
########## Bootstrap Infrastructure ###########
###############################################

# Reference existing S3 bucket for Terraform state
data "aws_s3_bucket" "terraform_state" {
  bucket = "auto-rmf-terraform-state"
}

# Reference existing DynamoDB table for state locking
data "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-state-lock"
}

##############################################
############ AWS Organizations  ##############
##############################################

# Reference existing AWS Organization
data "aws_organizations_organization" "main" {}

# Organization CloudTrail
resource "aws_cloudtrail" "organization_trail" {
  name                          = "auto-rmf-org-trail"
  s3_bucket_name                = var.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}

# Reference existing GuardDuty detector
data "aws_guardduty_detector" "main" {
  id = "c0cd6ff978a636b902d873e13411b874"
}

resource "aws_guardduty_organization_admin_account" "security" {
  admin_account_id = var.security_account_id
}

# Security Hub organization configuration
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_organization_admin_account" "security" {
  admin_account_id = var.security_account_id

  depends_on = [aws_securityhub_account.main]
}

# Service Control Policies
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
            "s3:x-amz-server-side-encryption" = "AES256"
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

resource "aws_organizations_policy_attachment" "require_encryption" {
  policy_id = aws_organizations_policy.require_encryption.id
  target_id = data.aws_organizations_organization.main.roots[0].id
}

# Budget alerts
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
