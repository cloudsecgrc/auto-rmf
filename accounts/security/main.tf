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
    key            = "security/terraform.tfstate"
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
      Account     = "Security"
    }
  }
}

########### LOCAL VARIABLES ###########
locals {
  evidence_bucket_name = "auto-rmf-evidence-collection"
}

##############################################################################
##############################################################################

########### CONFIG AGGREGATOR FOR ORGANIZATION ###########
resource "aws_config_configuration_aggregator" "organization" {
  count = var.enable_config_aggregator ? 1 : 0

  name = "auto-rmf-org-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator[0].arn
  }
}

########### CONFIG AGGREGATOR IAM ROLE ###########
resource "aws_iam_role" "config_aggregator" {
  count = var.enable_config_aggregator ? 1 : 0

  name = "ConfigAggregatorRole"

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

########### CONFIG AGGREGATOR IAM ROLE POLICY ###########
resource "aws_iam_role_policy_attachment" "config_aggregator" {
  count = var.enable_config_aggregator ? 1 : 0

  role       = aws_iam_role.config_aggregator[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

##############################################################################
##############################################################################

########### KMS KEY - SNS ENCRYPTION ###########
resource "aws_kms_key" "sns" {
  description             = "KMS key for AUTO-RMF SNS topics"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EventBridge to use the key"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

########### KMS ALIAS - SNS ###########
resource "aws_kms_alias" "sns" {
  name          = "alias/auto-rmf-sns"
  target_key_id = aws_kms_key.sns.key_id
}

##############################################################################
##############################################################################

########### SNS TOPIC - SECURITY HUB CRITICAL ###########
resource "aws_sns_topic" "security_hub_critical" {
  name              = "auto-rmf-securityhub-critical"
  kms_master_key_id = aws_kms_key.sns.id
}

########### SNS TOPIC - GUARDDUTY HIGH ###########
resource "aws_sns_topic" "guardduty_high" {
  name              = "auto-rmf-guardduty-high"
  kms_master_key_id = aws_kms_key.sns.id
}

########### SNS TOPIC - CONFIG NON-COMPLIANT ###########
resource "aws_sns_topic" "config_noncompliant" {
  name              = "auto-rmf-config-noncompliant"
  kms_master_key_id = aws_kms_key.sns.id
}

##############################################################################
##############################################################################

########### SNS TOPIC SUBSCRIPTION - SECURITY HUB CRITICAL ###########
resource "aws_sns_topic_subscription" "security_hub_critical" {
  topic_arn = aws_sns_topic.security_hub_critical.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

########### SNS TOPIC SUBSCRIPTION - GUARDDUTY HIGH ###########
resource "aws_sns_topic_subscription" "guardduty_high" {
  topic_arn = aws_sns_topic.guardduty_high.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

########### SNS TOPIC SUBSCRIPTION - CONFIG NON-COMPLIANT ###########
resource "aws_sns_topic_subscription" "config_noncompliant" {
  topic_arn = aws_sns_topic.config_noncompliant.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

##############################################################################
##############################################################################

########### SNS TOPIC POLICY - SECURITY HUB CRITICAL ###########
resource "aws_sns_topic_policy" "security_hub_critical" {
  arn = aws_sns_topic.security_hub_critical.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.security_hub_critical.arn
      }
    ]
  })
}

########### SNS TOPIC POLICY - GUARDDUTY HIGH ###########
resource "aws_sns_topic_policy" "guardduty_high" {
  arn = aws_sns_topic.guardduty_high.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.guardduty_high.arn
      }
    ]
  })
}

########### SNS TOPIC POLICY - CONFIG NON-COMPLIANT ###########
resource "aws_sns_topic_policy" "config_noncompliant" {
  arn = aws_sns_topic.config_noncompliant.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.config_noncompliant.arn
      }
    ]
  })
}

##############################################################################
##############################################################################

########### EVENTBRIDGE RULE - SECURITY HUB CRITICAL ###########
resource "aws_cloudwatch_event_rule" "security_hub_critical" {
  name        = "auto-rmf-securityhub-critical"
  description = "Capture Security Hub critical findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["CRITICAL"]
        }
      }
    }
  })
}

########### EVENTBRIDGE TARGET - SECURITY HUB CRITICAL ###########
resource "aws_cloudwatch_event_target" "security_hub_critical" {
  rule      = aws_cloudwatch_event_rule.security_hub_critical.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_hub_critical.arn
}

##############################################################################
##############################################################################

########### EVENTBRIDGE RULE - GUARDDUTY HIGH ###########
resource "aws_cloudwatch_event_rule" "guardduty_high" {
  name        = "auto-rmf-guardduty-high"
  description = "Capture GuardDuty high severity findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        { numeric = [">", 7] }
      ]
    }
  })
}

########### EVENTBRIDGE TARGET - GUARDDUTY HIGH ###########
resource "aws_cloudwatch_event_target" "guardduty_high" {
  rule      = aws_cloudwatch_event_rule.guardduty_high.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_high.arn
}

##############################################################################
##############################################################################

########### EVENTBRIDGE RULE - CONFIG NON-COMPLIANT ###########
resource "aws_cloudwatch_event_rule" "config_noncompliant" {
  name        = "auto-rmf-config-noncompliant"
  description = "Capture Config non-compliant resources"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })
}

########### EVENTBRIDGE TARGET - CONFIG NON-COMPLIANT ###########
resource "aws_cloudwatch_event_target" "config_noncompliant" {
  rule      = aws_cloudwatch_event_rule.config_noncompliant.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.config_noncompliant.arn
}

##############################################################################
##############################################################################

########### LAMBDA FUNCTION - EVIDENCE COLLECTOR ###########
resource "aws_lambda_function" "evidence_collector" {
  count = var.enable_evidence_collector ? 1 : 0

  filename         = "${path.module}/lambda/evidence_collector.zip"
  function_name    = "auto-rmf-evidence-collector"
  role             = aws_iam_role.lambda_evidence[0].arn
  handler          = "evidence_collector.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/evidence_collector.zip")
  runtime          = "python3.11"
  timeout          = 300

  environment {
    variables = {
      EVIDENCE_BUCKET     = local.evidence_bucket_name
      SECURITY_ACCOUNT_ID = var.security_account_id
    }
  }
}

########### LAMBDA IAM ROLE - EVIDENCE COLLECTOR ###########
resource "aws_iam_role" "lambda_evidence" {
  count = var.enable_evidence_collector ? 1 : 0

  name = "LambdaEvidenceCollectorRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

########### LAMBDA IAM ROLE POLICY - EVIDENCE COLLECTOR ###########
resource "aws_iam_role_policy" "lambda_evidence" {
  count = var.enable_evidence_collector ? 1 : 0

  name = "LambdaEvidenceCollectorPolicy"
  role = aws_iam_role.lambda_evidence[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${local.evidence_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:GetFindings",
          "guardduty:ListFindings",
          "guardduty:GetFindings",
          "config:DescribeComplianceByConfigRule",
          "config:GetComplianceDetailsByConfigRule"
        ]
        Resource = "*"
      }
    ]
  })
}

########### EVENTBRIDGE RULE - EVIDENCE COLLECTION ###########
resource "aws_cloudwatch_event_rule" "evidence_collection" {
  count = var.enable_evidence_collector ? 1 : 0

  name                = "auto-rmf-evidence-collection"
  description         = "Trigger evidence collection daily"
  schedule_expression = "cron(0 6 * * ? *)"
}

########### EVENTBRIDGE TARGET - EVIDENCE COLLECTION ###########
resource "aws_cloudwatch_event_target" "evidence_collection" {
  count = var.enable_evidence_collector ? 1 : 0

  rule      = aws_cloudwatch_event_rule.evidence_collection[0].name
  target_id = "LambdaFunction"
  arn       = aws_lambda_function.evidence_collector[0].arn
}

########### LAMBDA PERMISSION - EVIDENCE COLLECTION ###########
resource "aws_lambda_permission" "evidence_collection" {
  count = var.enable_evidence_collector ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.evidence_collector[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.evidence_collection[0].arn
}

##############################################################################
##############################################################################

########### SECURITY SERVICES MODULE ###########
module "security_services" {
  source = "../../modules/security-services"

  aws_region = var.aws_region
  account_id = var.security_account_id
}

########### COMPLIANCE BASELINE MODULE ###########
module "compliance_baseline" {
  source = "../../modules/compliance-baseline"

  depends_on = [module.security_services]
  aws_region = var.aws_region
  account_id = var.security_account_id
}
