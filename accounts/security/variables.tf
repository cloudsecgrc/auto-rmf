variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "security_account_id" {
  description = "Security account ID"
  type        = string
}

variable "management_account_id" {
  description = "Management account ID"
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

variable "evidence_bucket_name" {
  description = "S3 bucket name for evidence collection"
  type        = string
  default     = "auto-rmf-evidence-collection"
}

variable "alert_email" {
  description = "Email address for security alerts"
  type        = string
}
