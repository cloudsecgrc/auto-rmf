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
