########### TERRAFORM VERSION ###########
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

########### BACKEND ###########
  backend "s3" {
    bucket         = "auto-rmf-terraform-state"
    key            = "workload/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

########### PROVIDER ###########
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "AUTO-RMF"
      ManagedBy   = "Terraform"
      Environment = "Production"
      Account     = "Workload"
    }
  }
}

########### LOCAL VARIABLES ###########
locals {
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidr    = "10.0.1.0/24"
  app_private_subnet_cidr = "10.0.2.0/24"
  db_private_subnet_cidr  = "10.0.3.0/24"
  vpc_flow_logs_bucket  = "auto-rmf-vpc-flow-logs"
}

##############################################################################
##############################################################################
########### VPC & NETWORKING #################################################
##############################################################################
##############################################################################

########### VPC ###########
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "auto-rmf-vpc"
  }
}

########### INTERNET GATEWAY ###########
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "auto-rmf-igw"
  }
}

##############################################################################
##############################################################################
########### SUBNETS ##########################################################
##############################################################################
##############################################################################

########### PUBLIC SUBNET ###########
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "auto-rmf-public-subnet"
    Tier = "Public"
  }
}

########### APPLICATION PRIVATE SUBNET ###########
resource "aws_subnet" "app_private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.app_private_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "auto-rmf-app-private-subnet"
    Tier = "Application"
  }
}

########### DATABASE PRIVATE SUBNET ###########
resource "aws_subnet" "db_private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.db_private_subnet_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "auto-rmf-db-private-subnet"
    Tier = "Database"
  }
}

##############################################################################
##############################################################################
########### ROUTE TABLES #####################################################
##############################################################################
##############################################################################

########### PUBLIC ROUTE TABLE ###########
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "auto-rmf-public-rt"
  }
}

########### PUBLIC ROUTE TABLE ASSOCIATION ###########
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

########### PRIVATE ROUTE TABLE - APPLICATION ###########
resource "aws_route_table" "app_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "auto-rmf-app-private-rt"
  }
}

########### PRIVATE ROUTE TABLE ASSOCIATION - APPLICATION ###########
resource "aws_route_table_association" "app_private" {
  subnet_id      = aws_subnet.app_private.id
  route_table_id = aws_route_table.app_private.id
}

########### PRIVATE ROUTE TABLE - DATABASE ###########
resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "auto-rmf-db-private-rt"
  }
}

########### PRIVATE ROUTE TABLE ASSOCIATION - DATABASE ###########
resource "aws_route_table_association" "db_private" {
  subnet_id      = aws_subnet.db_private.id
  route_table_id = aws_route_table.db_private.id
}

##############################################################################
##############################################################################
########### NETWORK ACLs #####################################################
##############################################################################
##############################################################################

########### PUBLIC NACL ###########
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public.id]

  tags = {
    Name = "auto-rmf-public-nacl"
  }
}

########### PUBLIC NACL - INGRESS HTTPS ###########
resource "aws_network_acl_rule" "public_ingress_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
  egress         = false
}

########### PUBLIC NACL - INGRESS HTTP ###########
resource "aws_network_acl_rule" "public_ingress_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
  egress         = false
}

########### PUBLIC NACL - INGRESS EPHEMERAL ###########
resource "aws_network_acl_rule" "public_ingress_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
  egress         = false
}

########### PUBLIC NACL - EGRESS ALL ###########
resource "aws_network_acl_rule" "public_egress_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}

##############################################################################
##############################################################################

########### APPLICATION NACL ###########
resource "aws_network_acl" "app_private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.app_private.id]

  tags = {
    Name = "auto-rmf-app-private-nacl"
  }
}

########### APP NACL - INGRESS VPC ONLY ###########
resource "aws_network_acl_rule" "app_ingress_vpc" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = local.vpc_cidr
  egress         = false
}

########### APP NACL - EGRESS ALL ###########
resource "aws_network_acl_rule" "app_egress_all" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}

##############################################################################
##############################################################################

########### DATABASE NACL ###########
resource "aws_network_acl" "db_private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.db_private.id]

  tags = {
    Name = "auto-rmf-db-private-nacl"
  }
}

########### DB NACL - INGRESS VPC ONLY ###########
resource "aws_network_acl_rule" "db_ingress_vpc" {
  network_acl_id = aws_network_acl.db_private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = local.vpc_cidr
  egress         = false
}

########### DB NACL - EGRESS ALL ###########
resource "aws_network_acl_rule" "db_egress_all" {
  network_acl_id = aws_network_acl.db_private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}

##############################################################################
##############################################################################
########### SECURITY GROUPS ##################################################
##############################################################################
##############################################################################

########### WEB TIER SECURITY GROUP ###########
resource "aws_security_group" "web_tier" {
  name        = "auto-rmf-web-tier-sg"
  description = "Security group for web tier (ALB/WAF)"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "auto-rmf-web-tier-sg"
    Tier = "Web"
  }
}

########### WEB TIER SG - INGRESS HTTPS ###########
resource "aws_security_group_rule" "web_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_tier.id
  description       = "Allow HTTPS from internet"
}

########### WEB TIER SG - INGRESS HTTP ###########
resource "aws_security_group_rule" "web_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_tier.id
  description       = "Allow HTTP from internet"
}

########### WEB TIER SG - EGRESS ALL ###########
resource "aws_security_group_rule" "web_egress_app" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_tier.id
  security_group_id        = aws_security_group.web_tier.id
  description              = "Allow traffic to application tier"
}

resource "aws_security_group_rule" "web_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_tier.id
  description       = "Allow all outbound traffic"
}

##############################################################################
##############################################################################

########### APPLICATION TIER SECURITY GROUP ###########
resource "aws_security_group" "app_tier" {
  name        = "auto-rmf-app-tier-sg"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "auto-rmf-app-tier-sg"
    Tier = "Application"
  }
}

########### APP TIER SG - INGRESS FROM WEB TIER ###########
resource "aws_security_group_rule" "app_ingress_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_tier.id
  security_group_id        = aws_security_group.app_tier.id
  description              = "Allow traffic from web tier"
}

########### APP TIER SG - EGRESS ALL ###########
resource "aws_security_group_rule" "app_egress_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_tier.id
  security_group_id        = aws_security_group.app_tier.id
  description              = "Allow MySQL to database tier"
}

##############################################################################
##############################################################################

########### DATABASE TIER SECURITY GROUP ###########
resource "aws_security_group" "db_tier" {
  name        = "auto-rmf-db-tier-sg"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "auto-rmf-db-tier-sg"
    Tier = "Database"
  }
}

########### DB TIER SG - INGRESS FROM APP TIER ###########
resource "aws_security_group_rule" "db_ingress_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_tier.id
  security_group_id        = aws_security_group.db_tier.id
  description              = "Allow MySQL from app tier"
}

########### DB TIER SG - EGRESS VPC ONLY ###########
# NO EGRESS FOR DATABASE SG - BEST PRACTICE

##############################################################################
##############################################################################
########### VPC FLOW LOGS ###########
##############################################################################
##############################################################################

########### VPC FLOW LOGS ###########
resource "aws_flow_log" "main" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination      = "arn:aws:s3:::${local.vpc_flow_logs_bucket}"
  log_destination_type = "s3"

  tags = {
    Name = "auto-rmf-vpc-flow-logs"
  }
}

##############################################################################
##############################################################################
########### SECURITY SERVICES MODULE #########################################
##############################################################################
##############################################################################

module "security_services" {
  source = "../../modules/security-services"

  aws_region = var.aws_region
  account_id = var.workload_account_id
}

##############################################################################
##############################################################################
############# COMPLIANCE BASELINE MODULE #####################################
##############################################################################
##############################################################################

module "compliance_baseline" {
  source = "../../modules/compliance-baseline"

  depends_on = [module.security_services]
  aws_region = var.aws_region
  account_id = var.workload_account_id
}
