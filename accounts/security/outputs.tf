output "config_aggregator_name" {
  description = "Config aggregator name"
  value       = var.enable_config_aggregator ? aws_config_configuration_aggregator.organization[0].name : null
}

output "security_hub_critical_topic_arn" {
  description = "Security Hub critical findings SNS topic ARN"
  value       = aws_sns_topic.security_hub_critical.arn
}

output "guardduty_high_topic_arn" {
  description = "GuardDuty high severity SNS topic ARN"
  value       = aws_sns_topic.guardduty_high.arn
}

output "config_noncompliant_topic_arn" {
  description = "Config non-compliant SNS topic ARN"
  value       = aws_sns_topic.config_noncompliant.arn
}

output "evidence_collector_function_name" {
  description = "Evidence collector Lambda function name"
  value       = var.enable_evidence_collector ? aws_lambda_function.evidence_collector[0].function_name : null
}
