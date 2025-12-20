variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "logging_account_id" {
  description = "Logging account ID"
  type        = string
}

variable "workload_account_id" {
  description = "Workload account ID"
  type        = string
}