output "security_hub_critical_topic_arn" {
  description = "Security Hub critical findings SNS topic ARN"
  value       = aws_sns_topic.security_hub_critical.arn
}

output "guardduty_high_topic_arn" {
  description = "GuardDuty high severity findings SNS topic ARN"
  value       = aws_sns_topic.guardduty_high.arn
}

output "config_noncompliant_topic_arn" {
  description = "Config non-compliant resources SNS topic ARN"
  value       = aws_sns_topic.config_noncompliant.arn
}

output "evidence_collector_function_arn" {
  description = "Evidence collector Lambda function ARN"
  value       = aws_lambda_function.evidence_collector.arn
}

output "config_aggregator_name" {
  description = "Config aggregator name"
  value       = aws_config_configuration_aggregator.organization.name
}

output "config_aggregator_arn" {
  description = "Config aggregator ARN"
  value       = aws_config_configuration_aggregator.organization.arn
}