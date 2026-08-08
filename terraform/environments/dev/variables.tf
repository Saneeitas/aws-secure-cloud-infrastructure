# Dev Environment - Variable Declarations
# Variables with defaults are safe for any environment.
# Variables without defaults are sensitive/environment-specific and require explicit input.

# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region for resource deployment (default: us-east-1)"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Common Tagging
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used in resource naming and tagging (default: aws-secure-infrastructure)"
  type        = string
  default     = "aws-secure-infrastructure"
}

variable "environment" {
  description = "Environment name for tagging (default: dev)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner identifier for resource tagging. Provide your name or team identifier (e.g., 'security-team' or 'john.doe@example.com')"
  type        = string
}

# -----------------------------------------------------------------------------
# KMS Module Variables
# -----------------------------------------------------------------------------

variable "kms_admin_arns" {
  description = "List of IAM principal ARNs granted KMS key administration (e.g., ['arn:aws:iam::123456789012:role/admin'])"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# S3 Module Variables
# -----------------------------------------------------------------------------

variable "s3_bucket_name" {
  description = "Globally unique name for the primary S3 bucket (e.g., 'my-org-secure-data-dev')"
  type        = string
}

variable "allowed_principal_arns" {
  description = "List of IAM principal ARNs allowed to access the S3 bucket and use the KMS key (e.g., ['arn:aws:iam::123456789012:role/app-role'])"
  type        = list(string)
}

variable "inventory_destination_bucket_arn" {
  description = "ARN of the S3 bucket to receive inventory reports (e.g., 'arn:aws:s3:::my-inventory-bucket')"
  type        = string
}

# -----------------------------------------------------------------------------
# Network Module Variables
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the primary VPC (default: 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "management_subnet_cidr" {
  description = "CIDR block for the management subnet (default: 10.0.1.0/24)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "workload_subnet_cidr" {
  description = "CIDR block for the workload subnet (default: 10.0.2.0/24)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "enable_network_firewall" {
  description = "Enable AWS Network Firewall (WARNING: ~$0.395/hr cost). Default: false"
  type        = bool
  default     = false
}

variable "firewall_drop_port" {
  description = "TCP port to block in the Network Firewall stateful rules (default: 8080)"
  type        = number
  default     = 8080
}

# -----------------------------------------------------------------------------
# Compute Module Variables
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type (default: t3.micro for free tier eligibility)"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the EC2 instance (e.g., '203.0.113.0/24'). No default - must be explicitly provided."
  type        = string
}

# -----------------------------------------------------------------------------
# Monitoring Module Variables
# -----------------------------------------------------------------------------

variable "notification_email" {
  description = "Email address for SNS security alert notifications (e.g., 'alerts@example.com'). No default - must be provided."
  type        = string
}
