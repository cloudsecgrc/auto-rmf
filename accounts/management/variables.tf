variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "security_account_id" {
  description = "Security account ID for delegated admin"
  type        = string
}

variable "logging_account_id" {
  description = "Logging account ID"
  type        = string
}

variable "workload_account_id" {
  description = "Workload account ID"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (must exist in logging account)"
  type        = string
}

variable "alert_email" {
  description = "Email address for budget and security alerts"
  type        = string
}
