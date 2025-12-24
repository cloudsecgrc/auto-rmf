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
    key            = "logging/terraform.tfstate"
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
      Account     = "Logging"
    }
  }
}

########### LOCAL VARIABLES ###########
locals {
  cloudtrail_bucket_name     = "auto-rmf-cloudtrail-logs"
  config_snapshots_bucket    = "auto-rmf-config-snapshots"
  vpc_flow_logs_bucket       = "auto-rmf-vpc-flow-logs"
  cloudwatch_logs_bucket     = "auto-rmf-cloudwatch-logs"
  evidence_collection_bucket = "auto-rmf-evidence-collection"
}

##############################################################################
##############################################################################

########### KMS KEY - S3 LOGGING ENCRYPTION ###########
resource "aws_kms_key" "s3_logging" {
  description             = "KMS key for AUTO-RMF S3 logging buckets"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.logging_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DecryptDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${var.management_account_id}:trail/auto-rmf-org-trail"
          }
        }
      },
      {
        Sid    = "Allow Config to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow VPC Flow Logs"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

########### KMS ALIAS ###########
resource "aws_kms_alias" "s3_logging" {
  name          = "alias/auto-rmf-s3-logging"
  target_key_id = aws_kms_key.s3_logging.key_id
}

##############################################################################
##############################################################################

########### S3 BUCKET - CLOUDTRAIL LOGS ###########
resource "aws_s3_bucket" "cloudtrail" {
  bucket = local.cloudtrail_bucket_name
}

########### S3 BUCKET VERSIONING - CLOUDTRAIL ###########
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

########### S3 BUCKET ENCRYPTION - CLOUDTRAIL ###########
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_logging.arn
    }
  }
}

########### S3 BUCKET PUBLIC ACCESS BLOCK - CLOUDTRAIL ###########
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########### S3 BUCKET POLICY - CLOUDTRAIL ###########
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.management_account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWriteOrg"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.organization_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

##############################################################################
##############################################################################

########### S3 BUCKET - CONFIG SNAPSHOTS ###########
resource "aws_s3_bucket" "config_snapshots" {
  bucket = local.config_snapshots_bucket
}

########### S3 BUCKET VERSIONING - CONFIG ###########
resource "aws_s3_bucket_versioning" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  versioning_configuration {
    status = "Enabled"
  }
}

########### S3 BUCKET ENCRYPTION - CONFIG ###########
resource "aws_s3_bucket_server_side_encryption_configuration" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_logging.arn
    }
  }
}

########### S3 BUCKET PUBLIC ACCESS BLOCK - CONFIG ###########
resource "aws_s3_bucket_public_access_block" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########### S3 BUCKET POLICY - CONFIG ###########
resource "aws_s3_bucket_policy" "config_snapshots" {
  bucket = aws_s3_bucket.config_snapshots.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_snapshots.arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config_snapshots.arn
      },
      {
        Sid    = "AWSConfigWrite"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_snapshots.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

##############################################################################
##############################################################################

########### S3 BUCKET - VPC FLOW LOGS ###########
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = local.vpc_flow_logs_bucket
}

########### S3 BUCKET VERSIONING - VPC FLOW LOGS ###########
resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

########### S3 BUCKET ENCRYPTION - VPC FLOW LOGS ###########
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_logging.arn
    }
  }
}

########### S3 BUCKET PUBLIC ACCESS BLOCK - VPC FLOW LOGS ###########
resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########### S3 BUCKET POLICY - VPC FLOW LOGS ###########
resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.vpc_flow_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = var.workload_account_id
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.vpc_flow_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.workload_account_id
          }
        }
      }
    ]
  })
}

##############################################################################
##############################################################################

########### S3 BUCKET - CLOUDWATCH LOGS ###########
resource "aws_s3_bucket" "cloudwatch_logs" {
  bucket = local.cloudwatch_logs_bucket
}

########### S3 BUCKET VERSIONING - CLOUDWATCH ###########
resource "aws_s3_bucket_versioning" "cloudwatch_logs" {
  bucket = aws_s3_bucket.cloudwatch_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

########### S3 BUCKET ENCRYPTION - CLOUDWATCH ###########
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudwatch_logs" {
  bucket = aws_s3_bucket.cloudwatch_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_logging.arn
    }
  }
}

########### S3 BUCKET PUBLIC ACCESS BLOCK - CLOUDWATCH ###########
resource "aws_s3_bucket_public_access_block" "cloudwatch_logs" {
  bucket = aws_s3_bucket.cloudwatch_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

##############################################################################
##############################################################################

########### S3 BUCKET - EVIDENCE COLLECTION ###########
resource "aws_s3_bucket" "evidence" {
  bucket = local.evidence_collection_bucket
}

########### S3 BUCKET VERSIONING - EVIDENCE ###########
resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  versioning_configuration {
    status = "Enabled"
  }
}

########### S3 BUCKET ENCRYPTION - EVIDENCE ###########
resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_logging.arn
    }
  }
}

########### S3 BUCKET PUBLIC ACCESS BLOCK - EVIDENCE ###########
resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########### S3 BUCKET POLICY - EVIDENCE ###########
resource "aws_s3_bucket_policy" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecurityAccountLambdaWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:role/LambdaEvidenceCollectorRole"
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.evidence.arn}/*"
      },
      {
        Sid    = "AllowSecurityAccountListBucket"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:role/LambdaEvidenceCollectorRole"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.evidence.arn
      }
    ]
  })
}

##############################################################################
##############################################################################

########### SECURITY SERVICES MODULE ###########
module "security_services" {
  source = "../../modules/security-services"

  aws_region = var.aws_region
  account_id = var.logging_account_id
}

########### COMPLIANCE BASELINE MODULE ###########
module "compliance_baseline" {
  source = "../../modules/compliance-baseline"

  depends_on = [module.security_services]
  aws_region = var.aws_region
  account_id = var.logging_account_id
}
