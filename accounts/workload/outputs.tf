########### VPC OUTPUTS ###########
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

########### SUBNET OUTPUTS ###########
output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "Public subnet CIDR"
  value       = aws_subnet.public.cidr_block
}

output "app_private_subnet_id" {
  description = "Application private subnet ID"
  value       = aws_subnet.app_private.id
}

output "app_private_subnet_cidr" {
  description = "Application private subnet CIDR"
  value       = aws_subnet.app_private.cidr_block
}

output "db_private_subnet_id" {
  description = "Database private subnet ID"
  value       = aws_subnet.db_private.id
}

output "db_private_subnet_cidr" {
  description = "Database private subnet CIDR"
  value       = aws_subnet.db_private.cidr_block
}

########### ROUTE TABLE OUTPUTS ###########
output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "app_private_route_table_id" {
  description = "Application private route table ID"
  value       = aws_route_table.app_private.id
}

output "db_private_route_table_id" {
  description = "Database private route table ID"
  value       = aws_route_table.db_private.id
}

########### NETWORK ACL OUTPUTS ###########
output "public_nacl_id" {
  description = "Public NACL ID"
  value       = aws_network_acl.public.id
}

output "app_private_nacl_id" {
  description = "Application private NACL ID"
  value       = aws_network_acl.app_private.id
}

output "db_private_nacl_id" {
  description = "Database private NACL ID"
  value       = aws_network_acl.db_private.id
}

########### SECURITY GROUP OUTPUTS ###########
output "web_tier_sg_id" {
  description = "Web tier security group ID"
  value       = aws_security_group.web_tier.id
}

output "app_tier_sg_id" {
  description = "Application tier security group ID"
  value       = aws_security_group.app_tier.id
}

output "db_tier_sg_id" {
  description = "Database tier security group ID"
  value       = aws_security_group.db_tier.id
}

########### VPC FLOW LOGS OUTPUT ###########
output "vpc_flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.main.id
}