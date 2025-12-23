output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.main.id
}

output "organization_root_id" {
  description = "AWS Organization root ID"
  value       = data.aws_organizations_organization.main.roots[0].id
}

output "cloudtrail_name" {
  description = "Organization CloudTrail name"
  value       = aws_cloudtrail.organization_trail.name
}

output "guardduty_delegated_admin" {
  description = "GuardDuty delegated admin account ID"
  value       = aws_organizations_delegated_administrator.guardduty.account_id
}

output "securityhub_delegated_admin" {
  description = "Security Hub delegated admin account ID"
  value       = aws_organizations_delegated_administrator.securityhub.account_id
}

output "config_delegated_admin" {
  description = "Config delegated admin account ID"
  value       = aws_organizations_delegated_administrator.config.account_id
}

output "terraform_state_bucket" {
  description = "Terraform state S3 bucket"
  value       = data.aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table" {
  description = "Terraform state lock DynamoDB table"
  value       = data.aws_dynamodb_table.terraform_lock.name
}
