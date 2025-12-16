import json
import boto3
import os
from datetime import datetime, timezone

s3 = boto3.client('s3')
securityhub = boto3.client('securityhub')
guardduty = boto3.client('guardduty')
config = boto3.client('config')

EVIDENCE_BUCKET = os.environ['EVIDENCE_BUCKET']
SECURITY_ACCOUNT_ID = os.environ['SECURITY_ACCOUNT_ID']

def lambda_handler(event, context):
    """
    Collect security findings and compliance evidence from:
    - Security Hub
    - GuardDuty
    - Config
    
    Store evidence in S3 bucket for RMF compliance reporting.
    """
    
    timestamp = datetime.now(timezone.utc).strftime('%Y-%m-%d_%H-%M-%S')
    evidence = {
        'collection_time': timestamp,
        'security_hub_findings': collect_security_hub_findings(),
        'guardduty_findings': collect_guardduty_findings(),
        'config_compliance': collect_config_compliance()
    }
    
    # Upload evidence to S3
    s3_key = f'evidence/{timestamp}/compliance-evidence.json'
    s3.put_object(
        Bucket=EVIDENCE_BUCKET,
        Key=s3_key,
        Body=json.dumps(evidence, indent=2),
        ServerSideEncryption='AES256'
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Evidence collection completed',
            's3_location': f's3://{EVIDENCE_BUCKET}/{s3_key}',
            'findings_count': {
                'security_hub': len(evidence['security_hub_findings']),
                'guardduty': len(evidence['guardduty_findings']),
                'config': len(evidence['config_compliance'])
            }
        })
    }

def collect_security_hub_findings():
    """Collect Security Hub findings for evidence."""
    findings = []
    
    try:
        paginator = securityhub.get_paginator('get_findings')
        for page in paginator.paginate():
            for finding in page['Findings']:
                findings.append({
                    'id': finding['Id'],
                    'title': finding['Title'],
                    'severity': finding['Severity']['Label'],
                    'compliance_status': finding.get('Compliance', {}).get('Status', 'N/A'),
                    'resource_type': finding['Resources'][0]['Type'] if finding.get('Resources') else 'N/A',
                    'created_at': finding['CreatedAt']
                })
    except Exception as e:
        print(f"Error collecting Security Hub findings: {str(e)}")
    
    return findings

def collect_guardduty_findings():
    """Collect GuardDuty findings for evidence."""
    findings = []
    
    try:
        # Get all detectors
        detectors = guardduty.list_detectors()['DetectorIds']
        
        for detector_id in detectors:
            # Get finding IDs
            finding_ids = guardduty.list_findings(DetectorId=detector_id)['FindingIds']
            
            if finding_ids:
                # Get finding details
                finding_details = guardduty.get_findings(
                    DetectorId=detector_id,
                    FindingIds=finding_ids
                )['Findings']
                
                for finding in finding_details:
                    findings.append({
                        'id': finding['Id'],
                        'type': finding['Type'],
                        'severity': finding['Severity'],
                        'title': finding['Title'],
                        'description': finding['Description'],
                        'created_at': finding['CreatedAt']
                    })
    except Exception as e:
        print(f"Error collecting GuardDuty findings: {str(e)}")
    
    return findings

def collect_config_compliance():
    """Collect Config compliance status for evidence."""
    compliance_data = []
    
    try:
        # Get all config rules
        rules = config.describe_config_rules()['ConfigRules']
        
        for rule in rules:
            rule_name = rule['ConfigRuleName']
            
            # Get compliance details
            compliance = config.describe_compliance_by_config_rule(
                ConfigRuleNames=[rule_name]
            )
            
            if compliance['ComplianceByConfigRules']:
                compliance_info = compliance['ComplianceByConfigRules'][0]
                compliance_data.append({
                    'rule_name': rule_name,
                    'compliance_type': compliance_info['Compliance']['ComplianceType'],
                    'nist_control': rule.get('Description', 'N/A')  # Map to NIST control in description
                })
    except Exception as e:
        print(f"Error collecting Config compliance: {str(e)}")
    
    return compliance_data
