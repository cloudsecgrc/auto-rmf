variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "security_account_id" {
  description = "Security account ID"
  type        = string
}

variable "management_account_id" {
  description = "Management account ID"
  type        = string
}

variable "evidence_bucket_name" {
  description = "S3 bucket name for evidence collection"
  type        = string
}

variable "alert_email" {
  description = "Email address for security alerts"
  type        = string
}