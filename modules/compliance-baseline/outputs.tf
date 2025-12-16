output "config_rule_names" {
  description = "List of Config rule names for NIST 800-53 controls"
  value = [
    aws_config_config_rule.mfa_enabled.name,
    aws_config_config_rule.mfa_enabled_for_root.name,
    aws_config_config_rule.s3_bucket_public_read_prohibited.name,
    aws_config_config_rule.s3_bucket_public_write_prohibited.name,
    aws_config_config_rule.restricted_ssh.name,
    aws_config_config_rule.restricted_common_ports.name,
    aws_config_config_rule.cloudtrail_enabled.name,
    aws_config_config_rule.cloudtrail_log_file_validation.name,
    aws_config_config_rule.cloudtrail_encryption_enabled.name,
    aws_config_config_rule.config_enabled.name,
    aws_config_config_rule.securityhub_enabled.name,
    aws_config_config_rule.iam_user_unused_credentials_check.name,
    aws_config_config_rule.iam_password_policy.name,
    aws_config_config_rule.access_keys_rotated.name,
    aws_config_config_rule.vpc_flow_logs_enabled.name,
    aws_config_config_rule.alb_http_to_https_redirection_check.name,
    aws_config_config_rule.elb_tls_https_listeners_only.name,
    aws_config_config_rule.cmk_backing_key_rotation_enabled.name,
    aws_config_config_rule.s3_bucket_server_side_encryption_enabled.name,
    aws_config_config_rule.encrypted_volumes.name,
    aws_config_config_rule.ec2_ebs_encryption_by_default.name,
    aws_config_config_rule.ec2_instance_managed_by_systems_manager.name,
    aws_config_config_rule.guardduty_enabled_centralized.name,
    aws_config_config_rule.iam_policy_no_statements_with_admin_access.name,
    aws_config_config_rule.vpc_sg_open_only_to_authorized_ports.name,
    aws_config_config_rule.s3_bucket_logging_enabled.name,
    aws_config_config_rule.required_tags.name,
    aws_config_config_rule.rds_storage_encrypted.name
  ]
}
