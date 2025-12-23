########### TERRAFORM VERSION ###########
terraform {
  required_version = ">= 1.5.0"
}

##############################################################################
##############################################################################
########### AC - ACCESS CONTROL ##############################################
##############################################################################
##############################################################################

########### AC-2: ACCOUNT MANAGEMENT - ROOT ACCOUNT MFA ###########
resource "aws_config_config_rule" "root_account_mfa_enabled" {
  name = "root-account-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }
}

########### AC-2: ACCOUNT MANAGEMENT - IAM PASSWORD POLICY ###########
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

########### AC-2: ACCOUNT MANAGEMENT - IAM USER UNUSED CREDENTIALS ###########
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

########### AC-3: ACCESS ENFORCEMENT - IAM POLICY NO STATEMENTS WITH ADMIN ACCESS ###########
resource "aws_config_config_rule" "iam_policy_no_statements_with_admin_access" {
  name = "iam-policy-no-statements-with-admin-access"

  source {
    owner             = "AWS"
    source_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

########### AC-6: LEAST PRIVILEGE - IAM NO INLINE POLICY CHECK ###########
resource "aws_config_config_rule" "iam_no_inline_policy_check" {
  name = "iam-no-inline-policy-check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_NO_INLINE_POLICY_CHECK"
  }
}

##############################################################################
##############################################################################
########### AU - AUDIT AND ACCOUNTABILITY ####################################
##############################################################################
##############################################################################

########### AU-2: AUDIT EVENTS - CLOUDTRAIL ENABLED ###########
resource "aws_config_config_rule" "cloud_trail_enabled" {
  name = "cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
}

########### AU-9: PROTECTION OF AUDIT INFORMATION - CLOUDTRAIL LOG FILE VALIDATION ###########
resource "aws_config_config_rule" "cloud_trail_log_file_validation_enabled" {
  name = "cloudtrail-log-file-validation-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
  }
}

########### AU-9: PROTECTION OF AUDIT INFORMATION - CLOUDTRAIL ENCRYPTION ###########
resource "aws_config_config_rule" "cloud_trail_encryption_enabled" {
  name = "cloudtrail-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }
}

########### AU-12: AUDIT GENERATION - VPC FLOW LOGS ENABLED ###########
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "vpc-flow-logs-enabled"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
}

##############################################################################
##############################################################################
########### CM - CONFIGURATION MANAGEMENT ####################################
##############################################################################
##############################################################################

########### CM-2: BASELINE CONFIGURATION - EC2 INSTANCE MANAGED BY SSM ###########
resource "aws_config_config_rule" "ec2_instance_managed_by_systems_manager" {
  name = "ec2-instance-managed-by-systems-manager"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_MANAGED_BY_SSM"
  }
}

########### CM-6: CONFIGURATION SETTINGS - EC2 INSTANCES IN VPC ###########
resource "aws_config_config_rule" "instances_in_vpc" {
  name = "ec2-instances-in-vpc"

  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }
}

########### CM-7: LEAST FUNCTIONALITY - EC2 SECURITY GROUP UNRESTRICTED SSH ###########
resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
}

########### CM-7: LEAST FUNCTIONALITY - EC2 SECURITY GROUP UNRESTRICTED COMMON PORTS ###########
resource "aws_config_config_rule" "vpc_sg_open_only_to_authorized_ports" {
  name = "vpc-sg-open-only-to-authorized-ports"

  source {
    owner             = "AWS"
    source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
  }
}

##############################################################################
##############################################################################
########### IA - IDENTIFICATION AND AUTHENTICATION ###########################
##############################################################################
##############################################################################

########### IA-2: IDENTIFICATION AND AUTHENTICATION - MFA ENABLED FOR IAM CONSOLE ACCESS ###########
resource "aws_config_config_rule" "mfa_enabled_for_iam_console_access" {
  name = "mfa-enabled-for-iam-console-access"

  source {
    owner             = "AWS"
    source_identifier = "MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS"
  }
}

########### IA-5: AUTHENTICATOR MANAGEMENT - IAM USER NO POLICIES CHECK ###########
resource "aws_config_config_rule" "iam_user_no_policies_check" {
  name = "iam-user-no-policies-check"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_NO_POLICIES_CHECK"
  }
}

########### IA-5: AUTHENTICATOR MANAGEMENT - ACCESS KEYS ROTATED ###########
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

##############################################################################
##############################################################################
########### SC - SYSTEM AND COMMUNICATIONS PROTECTION ########################
##############################################################################
##############################################################################

########### SC-7: BOUNDARY PROTECTION - VPC DEFAULT SECURITY GROUP CLOSED ###########
resource "aws_config_config_rule" "vpc_default_security_group_closed" {
  name = "vpc-default-security-group-closed"

  source {
    owner             = "AWS"
    source_identifier = "VPC_DEFAULT_SECURITY_GROUP_CLOSED"
  }
}

########### SC-8: TRANSMISSION CONFIDENTIALITY - S3 BUCKET SSL REQUESTS ONLY ###########
resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  name = "s3-bucket-ssl-requests-only"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
}

########### SC-12: CRYPTOGRAPHIC KEY MANAGEMENT - KMS CMK NOT SCHEDULED FOR DELETION ###########
resource "aws_config_config_rule" "cmk_backing_key_rotation_enabled" {
  name = "cmk-backing-key-rotation-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }
}

########### SC-13: CRYPTOGRAPHIC PROTECTION - S3 BUCKET SERVER SIDE ENCRYPTION ENABLED ###########
resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}

########### SC-13: CRYPTOGRAPHIC PROTECTION - RDS STORAGE ENCRYPTED ###########
resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
}

########### SC-13: CRYPTOGRAPHIC PROTECTION - EBS ENCRYPTION BY DEFAULT ###########
resource "aws_config_config_rule" "ec2_ebs_encryption_by_default" {
  name = "ec2-ebs-encryption-by-default"

  source {
    owner             = "AWS"
    source_identifier = "EC2_EBS_ENCRYPTION_BY_DEFAULT"
  }
}

########### SC-28: PROTECTION OF INFORMATION AT REST - ENCRYPTED VOLUMES ###########
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
}

##############################################################################
##############################################################################

########### DATA SOURCE - CONFIG RECORDER ###########
data "aws_config_configuration_recorder" "main" {
  name = "auto-rmf-config-recorder"
}
