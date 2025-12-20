output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.main.id
}

output "organization_root_id" {
  description = "AWS Organization root ID"
  value       = data.aws_organizations_organization.main.roots[0].id
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = data.aws_guardduty_detector.main.id
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = data.aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table" {
  description = "DynamoDB table for state locking"
  value       = data.aws_dynamodb_table.terraform_lock.name
}