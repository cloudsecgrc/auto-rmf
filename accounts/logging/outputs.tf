output "cloudtrail_bucket_name" {
  description = "CloudTrail S3 bucket name"
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_bucket_arn" {
  description = "CloudTrail S3 bucket ARN"
  value       = aws_s3_bucket.cloudtrail.arn
}

output "config_bucket_name" {
  description = "Config snapshot S3 bucket name"
  value       = aws_s3_bucket.config_snapshots.id
}

output "vpc_flow_logs_bucket_name" {
  description = "VPC Flow Logs S3 bucket name"
  value       = aws_s3_bucket.vpc_flow_logs.id
}

output "evidence_bucket_name" {
  description = "Evidence collection S3 bucket name"
  value       = aws_s3_bucket.evidence.id
}

output "kms_key_id" {
  description = "KMS key ID for S3 encryption"
  value       = aws_kms_key.s3_logging.id
}

output "kms_key_arn" {
  description = "KMS key ARN for S3 encryption"
  value       = aws_kms_key.s3_logging.arn
}

output "config_aggregator_arn" {
  description = "Config aggregator ARN"
  value       = aws_config_configuration_aggregator.organization.arn
}

output "terraform_execution_role_arn" {
  description = "ARN of the execution role for CI/CD"
  value       = aws_iam_role.terraform_execution_role.arn
}