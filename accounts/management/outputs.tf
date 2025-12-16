output "organization_id" {
  description = "AWS Organization ID"
  value       = aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = aws_organizations_organization.main.arn
}

output "security_ou_id" {
  description = "Security OU ID"
  value       = aws_organizations_organizational_unit.security.id
}

output "infrastructure_ou_id" {
  description = "Infrastructure OU ID"
  value       = aws_organizations_organizational_unit.infrastructure.id
}

output "terraform_state_bucket" {
  description = "Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table" {
  description = "Terraform lock DynamoDB table"
  value       = aws_dynamodb_table.terraform_lock.id
}
