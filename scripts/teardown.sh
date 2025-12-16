#!/bin/bash

# AUTO-RMF Teardown Script
set -e

echo "====================================="
echo "AUTO-RMF Teardown Script"
echo "WARNING: This will destroy all infrastructure"
echo "====================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Teardown cancelled"
    exit 0
fi

destroy_account() {
    local account=$1
    local account_dir="accounts/$account"
    
    echo -e "${YELLOW}Destroying $account account...${NC}"
    
    cd $account_dir
    
    terraform destroy -auto-approve
    
    echo -e "${GREEN}✓ $account account destroyed${NC}"
    cd ../..
    echo ""
}

# Destroy in reverse order
echo "Destroying in reverse order..."
echo ""

destroy_account "workload"
destroy_account "security"
destroy_account "logging"
destroy_account "management"

echo ""
echo -e "${GREEN}====================================="
echo "Teardown Complete!"
echo "=====================================${NC}"
echo ""
echo "Note: S3 buckets may need manual deletion if they contain objects"
echo "Note: CloudWatch Logs may persist and incur minimal costs"
