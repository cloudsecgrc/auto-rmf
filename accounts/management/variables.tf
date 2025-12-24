variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "management_account_id" {
  description = "Management account ID"
  type        = string
}

variable "security_account_id" {
  description = "Security account ID for delegated admin"
  type        = string
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (exists in logging account)"
  type        = string
}

variable "auto-rmf-org-aggregator" {
  description = "org account"
}
variable "alert_email" {
  description = "Email address for budget and security alerts"
  type        = string
}