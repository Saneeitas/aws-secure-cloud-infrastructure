# Dev Environment - Main Configuration
# Wires all child modules together with common tags and inter-module dependencies.

provider "aws" {
  region = var.region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

# =============================================================================
# KMS MODULE - Must be provisioned first (other modules depend on key ARN)
# =============================================================================

module "kms" {
  source = "../../modules/kms"

  description          = "Customer-managed key for ${var.project_name} encryption"
  admin_principal_arns = var.kms_admin_arns
  usage_principal_arns = var.allowed_principal_arns
  tags                 = local.common_tags
}

# =============================================================================
# NETWORK MODULE - VPC, subnets, flow logs, optional Network Firewall
# =============================================================================

module "network" {
  source = "../../modules/network"

  vpc_cidr                = var.vpc_cidr
  management_subnet_cidr  = var.management_subnet_cidr
  workload_subnet_cidr    = var.workload_subnet_cidr
  enable_network_firewall = var.enable_network_firewall
  firewall_drop_port      = var.firewall_drop_port
  tags                    = local.common_tags
}

# =============================================================================
# S3 MODULE - Depends on KMS for encryption
# =============================================================================

module "s3" {
  source = "../../modules/s3"

  bucket_name                      = var.s3_bucket_name
  allowed_principal_arns           = var.allowed_principal_arns
  kms_key_arn                      = module.kms.key_arn
  inventory_destination_bucket_arn = var.inventory_destination_bucket_arn
  tags                             = local.common_tags
}

# =============================================================================
# COMPUTE MODULE - Depends on KMS (EBS encryption) and Network (subnet/VPC)
# =============================================================================

module "compute" {
  source = "../../modules/compute"

  instance_type    = var.instance_type
  subnet_id        = module.network.workload_subnet_id
  vpc_id           = module.network.vpc_id
  kms_key_arn      = module.kms.key_arn
  allowed_ssh_cidr = var.allowed_ssh_cidr
  tags             = local.common_tags
}

# =============================================================================
# MONITORING MODULE - Depends on S3, KMS, and Compute outputs
# =============================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  s3_bucket_arn      = module.s3.bucket_arn
  s3_bucket_name     = module.s3.bucket_name
  kms_key_arn        = module.kms.key_arn
  ec2_instance_id    = module.compute.instance_id
  notification_email = var.notification_email
  tags               = local.common_tags
}
