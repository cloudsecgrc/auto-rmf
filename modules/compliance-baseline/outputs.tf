output "config_rules" {
  description = "List of Config rule names"
  value = [
    aws_config_config_rule.root_account_mfa_enabled.name,
    aws_config_config_rule.iam_password_policy.name,
    aws_config_config_rule.iam_user_unused_credentials_check.name,
    aws_config_config_rule.iam_policy_no_statements_with_admin_access.name,
    aws_config_config_rule.iam_no_inline_policy_check.name,
    aws_config_config_rule.cloud_trail_enabled.name,
    aws_config_config_rule.cloud_trail_log_file_validation_enabled.name,
    aws_config_config_rule.cloud_trail_encryption_enabled.name,
    aws_config_config_rule.vpc_flow_logs_enabled.name,
    aws_config_config_rule.ec2_instance_managed_by_systems_manager.name,
    aws_config_config_rule.instances_in_vpc.name,
    aws_config_config_rule.restricted_ssh.name,
    aws_config_config_rule.vpc_sg_open_only_to_authorized_ports.name,
    aws_config_config_rule.mfa_enabled_for_iam_console_access.name,
    aws_config_config_rule.iam_user_no_policies_check.name,
    aws_config_config_rule.access_keys_rotated.name,
    aws_config_config_rule.vpc_default_security_group_closed.name,
    aws_config_config_rule.s3_bucket_ssl_requests_only.name,
    aws_config_config_rule.cmk_backing_key_rotation_enabled.name,
    aws_config_config_rule.s3_bucket_server_side_encryption_enabled.name,
    aws_config_config_rule.rds_storage_encrypted.name,
    aws_config_config_rule.ec2_ebs_encryption_by_default.name,
    aws_config_config_rule.encrypted_volumes.name
  ]
}

output "config_rules_count" {
  description = "Total number of Config rules deployed"
  value       = 23
}
