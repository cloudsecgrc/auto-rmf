output "cloudtrail_bucket_name" {
  description = "CloudTrail logs S3 bucket name"
  value       = aws_s3_bucket.cloudtrail.id
}

output "config_snapshots_bucket_name" {
  description = "Config snapshots S3 bucket name"
  value       = aws_s3_bucket.config_snapshots.id
}

output "vpc_flow_logs_bucket_name" {
  description = "VPC Flow Logs S3 bucket name"
  value       = aws_s3_bucket.vpc_flow_logs.id
}

output "cloudwatch_logs_bucket_name" {
  description = "CloudWatch Logs S3 bucket name"
  value       = aws_s3_bucket.cloudwatch_logs.id
}

output "evidence_collection_bucket_name" {
  description = "Evidence collection S3 bucket name"
  value       = aws_s3_bucket.evidence.id
}

output "s3_logging_kms_key_arn" {
  description = "KMS key ARN for S3 logging encryption"
  value       = aws_kms_key.s3_logging.arn
}
