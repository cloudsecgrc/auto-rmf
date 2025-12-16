output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "securityhub_account_id" {
  description = "Security Hub account ID"
  value       = aws_securityhub_account.main.id
}

output "config_recorder_id" {
  description = "Config recorder ID"
  value       = aws_config_configuration_recorder.main.id
}
