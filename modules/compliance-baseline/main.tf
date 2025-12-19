terraform {
  required_version = ">= 1.5.0"
}

# AC-2: Account Management - Enforce MFA
resource "aws_config_config_rule" "mfa_enabled" {
  name = "iam-root-access-key-check"
  
  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }
}

resource "aws_config_config_rule" "mfa_enabled_for_root" {
  name = "root-account-mfa-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
}

# AC-3: Access Enforcement - S3 bucket policies
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name = "s3-bucket-public-write-prohibited"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
}

# AC-4: Information Flow Enforcement - Security groups
resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"
  
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
}

resource "aws_config_config_rule" "restricted_common_ports" {
  name = "restricted-common-ports"
  
  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
}

# AU-2: Audit Events - CloudTrail logging
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "cloud-trail-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
}

resource "aws_config_config_rule" "cloudtrail_log_file_validation" {
  name = "cloud-trail-log-file-validation-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
  }
}

# AU-9: Protection of Audit Information - CloudTrail encryption
resource "aws_config_config_rule" "cloudtrail_encryption_enabled" {
  name = "cloud-trail-encryption-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }
}

# CM-2: Baseline Configuration - Config enabled
resource "aws_config_config_rule" "config_enabled" {
  name = "config-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "CONFIG_ENABLED"
  }
}

# CM-6: Configuration Settings - Security Hub enabled
resource "aws_config_config_rule" "securityhub_enabled" {
  name = "securityhub-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "SECURITYHUB_ENABLED"
  }
}

# CM-7: Least Functionality - Unused IAM credentials
resource "aws_config_config_rule" "iam_user_unused_credentials_check" {
  name = "iam-user-unused-credentials-check"
  
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }
  
  input_parameters = jsonencode({
    maxCredentialUsageAge = 90
  })
}

# IA-2: Identification and Authentication - IAM password policy
resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"
  
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  
  input_parameters = jsonencode({
    RequireUppercaseCharacters = true
    RequireLowercaseCharacters = true
    RequireSymbols             = true
    RequireNumbers             = true
    MinimumPasswordLength      = 14
    PasswordReusePrevention    = 24
    MaxPasswordAge             = 90
  })
}

# IA-5: Authenticator Management - No IAM keys for root
resource "aws_config_config_rule" "access_keys_rotated" {
  name = "access-keys-rotated"
  
  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }
  
  input_parameters = jsonencode({
    maxAccessKeyAge = 90
  })
}

# SC-7: Boundary Protection - VPC flow logs
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "vpc-flow-logs-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
}

# SC-8: Transmission Confidentiality - ELB HTTPS/TLS
resource "aws_config_config_rule" "alb_http_to_https_redirection_check" {
  name = "alb-http-to-https-redirection-check"
  
  source {
    owner             = "AWS"
    source_identifier = "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK"
  }
}

resource "aws_config_config_rule" "elb_tls_https_listeners_only" {
  name = "elb-tls-https-listeners-only"
  
  source {
    owner             = "AWS"
    source_identifier = "ELB_TLS_HTTPS_LISTENERS_ONLY"
  }
}

# SC-12: Cryptographic Key Management - KMS key rotation
resource "aws_config_config_rule" "cmk_backing_key_rotation_enabled" {
  name = "cmk-backing-key-rotation-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }
}

# SC-13: Cryptographic Protection - S3 encryption
resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "s3-bucket-server-side-encryption-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}

# SC-28: Protection of Information at Rest - EBS encryption
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
}

resource "aws_config_config_rule" "ec2_ebs_encryption_by_default" {
  name = "ec2-ebs-encryption-by-default"
  
  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
  }
}

# SI-2: Flaw Remediation - EC2 managed by SSM
resource "aws_config_config_rule" "ec2_instance_managed_by_systems_manager" {
  name = "ec2-instance-managed-by-systems-manager"
  
  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
  }
}

# SI-4: Information System Monitoring - GuardDuty enabled
resource "aws_config_config_rule" "guardduty_enabled_centralized" {
  name = "guardduty-enabled-centralized"
  
  source {
    owner             = "AWS"
    source_identifier = "GUARDDUTY_ENABLED_CENTRALIZED"
  }
}

# Additional controls for comprehensive coverage

# AC-6: Least Privilege - IAM policies
resource "aws_config_config_rule" "iam_policy_no_statements_with_admin_access" {
  name = "iam-policy-no-statements-with-admin-access"
  
  source {
    owner             = "AWS"
    source_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
  }
}

# SC-7(5): Deny by Default
resource "aws_config_config_rule" "vpc_sg_open_only_to_authorized_ports" {
  name = "vpc-sg-open-only-to-authorized-ports"
  
  source {
    owner             = "AWS"
    source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
  }
}

# AU-12: Audit Generation - S3 bucket logging
resource "aws_config_config_rule" "s3_bucket_logging_enabled" {
  name = "s3-bucket-logging-enabled"
  
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LOGGING_ENABLED"
  }
}

# CM-8: Information System Component Inventory - Config recording
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  
  input_parameters = jsonencode({
    tag1Key = "Project"
    tag2Key = "ManagedBy"
  })
}

# IA-4: Identifier Management - RDS encryption
resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "rds-storage-encrypted"
  
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
}
