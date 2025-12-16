# Auto-RMF

**Automated compliance evidence collection for 30 NIST 800-53 Rev 5 controls across AWS multi-account infrastructure.**

---

## Quick Summary

**The Problem:**
- Traditional RMF requires ISSOs to manually screenshot 300+ controls every assessment cycle
- Compliance becomes a quarterly burden instead of continuous validation
- Evidence collection takes weeks of manual labor with no real-time visibility

**The Solution:**
- Infrastructure-as-Code platform that continuously monitors compliance and auto-generates audit-ready evidence
- 4 AWS accounts (Management, Security, Logging, Workload) with Terraform managing defense-in-depth architecture
- Lambda function collects Security Hub findings, GuardDuty detections, and Config compliance status daily → exports timestamped JSON to S3 by control family

**Defense-in-Depth Implementation:**
- **WAF (Application Edge):** OWASP Top 10 protection, rate limiting (2000 req/5min), AWS managed rule sets
- **SCPs (Organization Level):** Organization-wide guardrails enforcing S3/EBS encryption, denying unencrypted uploads
- **IAM Permissions Boundaries (Role Level):** Automated policy attachment preventing admin access statements
- **Network Segmentation (Infrastructure Level):** Public subnets (WAF → ALB) + private subnets, NACLs + security group chains enforcing least-privilege

**Continuous Monitoring:**
- AWS Config evaluates 30 compliance rules on every configuration change (immediate, not daily)
- Security Hub aggregates findings into unified dashboard with CIS + NIST 800-53 Rev 5 standards
- GuardDuty analyzes VPC Flow Logs, CloudTrail, DNS queries 24/7 with ML-powered threat detection
- EventBridge triggers SNS alerts within minutes of critical/high-severity findings
- Daily automated evidence collection eliminates manual screenshot gathering

**Impact:**
- Weeks of manual evidence collection → Single Lambda invocation
- Point-in-time compliance snapshots → Real-time continuous validation
- Manual screenshot tracking → Automated audit-ready JSON evidence organized by control family

**Cost Estimate:**
- Fully deployed across 4 accounts: $100-150/month (GuardDuty $20-60, Config $20-40, Security Hub $12-20, VPC/ALB $20-30, S3/CloudTrail/misc $10-20

**Full Control Mapping:** [docs/CTM.csv](docs/CTM.csv)

---

## Quick Start

**Pre-Deployment Setup:**
Copy example configs to actual terraform.tfvars in each account directory (management, logging, security, workload). Configure your 4 AWS account IDs and alert email. Set up AWS CLI profiles with credentials for each account.

**Deployment Sequence (CRITICAL ORDER):**
1. Management account (Organizations, state backend, budgets, SCPs)
2. Logging account (S3 buckets, KMS, Config aggregator)
3. Security account (SNS, EventBridge, Lambda evidence collector)
4. Workload account (VPC, ALB, WAF, networking)


---

## Troubleshooting

**State Lock Issues:** Run `aws dynamodb scan --table-name terraform-state-lock` to list locks, then `terraform force-unlock LOCK_ID` if needed.

**Lambda Not Executing:** Check CloudWatch Logs with `aws logs tail /aws/lambda/auto-rmf-evidence-collector --follow` or manually invoke for testing.

**Config Non-Compliance:** Use `aws configservice describe-compliance-by-config-rule --config-rule-names RULE_NAME` for detailed status.

**Security Hub Findings:** List critical findings with `aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'`.

---

## Production Maintenance Looks Like This

**Daily Operations:**
- Review SNS email alerts for critical Security Hub/GuardDuty findings
- Check evidence collection S3 bucket for daily Lambda execution
- Monitor budget alerts for cost spikes (threshold: 80% of $50/month)

**Weekly Tasks:**
- Review Security Hub dashboard and remediate critical/high findings
- Check Config compliance aggregator across all accounts
- Verify CloudTrail logs delivering to S3 successfully

**Monthly Tasks:**
- Rotate IAM access keys (90-day policy enforced by Config)
- Review and optimize costs using AWS Cost Explorer
- Audit IAM policies for overly permissive access

---

## Evidence Collection

Evidence automatically collected daily at 6 AM UTC via EventBridge cron trigger. Lambda function queries Security Hub findings, GuardDuty detections, and Config compliance status, then exports timestamped JSON to `s3://auto-rmf-evidence-collection/evidence/YYYY-MM-DD_HH-MM-SS/compliance-evidence.json`. See `docs/CTM.csv` for NIST 800-53 control-to-AWS resource mapping.

**Manual Testing:** `aws lambda invoke --function-name auto-rmf-evidence-collector response.json`

---

## Disaster Recovery

**Backup State:** `aws s3 sync s3://auto-rmf-terraform-state ./state-backup/`

**Restore State:** `aws s3 sync ./state-backup/ s3://auto-rmf-terraform-state` then verify with `terraform plan`

**GitHub Actions Setup:** Create OIDC identity provider in AWS IAM and IAM role adding a trust relationship to your GitHub repo. Update `AWS_ROLE_ARN` in workflow `env:` section if using different role. CI/CD pipeline runs Terraform validation, security scanning (tfsec, Checkov), and automated deployment on merge to main.
---

## Tech Stack

**Infrastructure as Code:**
- Terraform (modular architecture, 4 separate state files)

**Compliance Monitoring:**
- AWS Security Hub, GuardDuty, Config, CloudTrail

**Evidence Collection:**
- Python 3.11 Lambda (boto3), EventBridge (daily cron trigger at 6 AM UTC)

**Logging/Storage:**
- S3 (encrypted with KMS, versioned, lifecycle policies), DynamoDB (state locking)

**Networking:**
- VPC, WAF, ALB, Security Groups, NACLs, VPC Flow Logs

**CI/CD:**
- GitHub Actions, tfsec, Checkov (automated security scanning against NIST 800-53)

---

## About Me

**Background:**
- 10 years in DoD (soldier → civilian → contractor)
- ISSO working in the cleared space while finishing Master's in Cyber Operations

**Why I Built This:**
- Traditional ISSO work is dying
- We're either evolving into "GRC Engineers" who automate compliance, or we're getting replaced by the engineers who figure it out first
- This project is my bet on evolving


**LinkedIn:** [linkedin.com/in/milestylerhall](https://www.linkedin.com/in/milestylerhall)

---

**License:** MIT | **Last Updated:** December 2025
