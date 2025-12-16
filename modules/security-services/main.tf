terraform {
  required_version = ">= 1.5.0"
}

# GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true
  
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false # not using kubernetes
      }
    }
  }
}

# Security Hub
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/cis-aws-foundations-benchmark/v/1.4.0"
  
  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "nist" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/nist-800-53/v/5.0.0"
  
  depends_on = [aws_securityhub_account.main]
}

# AWS Config
resource "aws_config_configuration_recorder" "main" {
  name     = "auto-rmf-config-recorder"
  role_arn = aws_iam_role.config.arn
  
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "auto-rmf-config-delivery"
  s3_bucket_name = "auto-rmf-config-snapshots"
  
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  
  depends_on = [aws_config_delivery_channel.main]
}

# Config IAM role
resource "aws_iam_role" "config" {
  name = "AWSConfigRole-${var.account_id}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  name = "ConfigS3Policy"
  role = aws_iam_role.config.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::auto-rmf-config-snapshots",
          "arn:aws:s3:::auto-rmf-config-snapshots/*"
        ]
      }
    ]
  })
}
