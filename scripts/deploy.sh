#!/bin/bash

# AUTO-RMF Complete Deployment Script
set -e

echo "====================================="
echo "AUTO-RMF Deployment Script"
echo "====================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check prerequisites
echo "Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}ERROR: terraform not found${NC}"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}ERROR: aws cli not found${NC}"; exit 1; }
echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# Deployment sequence
deploy_account() {
    local account=$1
    local account_dir="accounts/$account"
    
    echo -e "${YELLOW}Deploying $account account...${NC}"
    
    cd $account_dir
    
    # Check for tfvars
    if [ ! -f "terraform.tfvars" ]; then
        echo -e "${RED}ERROR: terraform.tfvars not found in $account_dir${NC}"
        echo "Copy terraform.tfvars.example to terraform.tfvars and configure"
        exit 1
    fi
    
    terraform init
    terraform plan -out=tfplan
    
    read -p "Apply plan for $account? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        terraform apply tfplan
        echo -e "${GREEN}✓ $account account deployed${NC}"
    else
        echo -e "${YELLOW}Skipped $account account${NC}"
    fi
    
    cd ../..
    echo ""
}

# Deploy in correct order
echo "====================================="
echo "Deployment Order:"
echo "1. Management (Organizations, state backend)"
echo "2. Logging (S3 buckets, Config aggregator)"
echo "3. Security (EventBridge, SNS, Lambda)"
echo "4. Workload (VPC, ALB, WAF)"
echo "====================================="
echo ""

read -p "Continue with deployment? (yes/no): " start
if [ "$start" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Deploy accounts in order
deploy_account "management"
deploy_account "logging"
deploy_account "security"
deploy_account "workload"

echo ""
echo -e "${GREEN}====================================="
echo "Deployment Complete!"
echo "=====================================${NC}"
echo ""
echo "Next steps:"
echo "1. Verify Security Hub standards in Security account"
echo "2. Check Config rules compliance in all accounts"
echo "3. Review GuardDuty findings"
echo "4. Test Lambda evidence collection"
echo ""
echo "Evidence collection runs daily at 6 AM UTC"
echo "Evidence location: s3://auto-rmf-evidence-collection/evidence/"
