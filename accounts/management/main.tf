terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "auto-rmf-terraform-state"
    key            = "management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

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

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "auto-rmf-terraform-state"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}

##############################################
############ AWS Organizations  ##############
##############################################

resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com"
  ]
  
  feature_set = "ALL"
  
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

# Organizational Units
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.main.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = aws_organizations_organization.main.roots[0].id
}

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
  
  depends_on = [aws_organizations_organization.main]
}

# GuardDuty organization configuration
resource "aws_guardduty_detector" "main" {
  enable = true
  
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_guardduty_organization_admin_account" "security" {
  admin_account_id = var.security_account_id
  
  depends_on = [aws_guardduty_detector.main]
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
        Sid    = "DenyUnencryptedS3Upload"
        Effect = "Deny"
        Action = "s3:PutObject"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedEBSVolumes"
        Effect = "Deny"
        Action = "ec2:RunInstances"
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
  target_id = aws_organizations_organization.main.roots[0].id
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

# IAM user for Terraform (using temporarily but will soon migrate to OIDC)
resource "aws_iam_user" "terraform" {
  name = "terraform-admin"
  path = "/automation/"
}

resource "aws_iam_user_policy_attachment" "terraform_admin" {
  user       = aws_iam_user.terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}