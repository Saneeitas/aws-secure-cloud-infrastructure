# Compute Module - Variable Declarations

# Cost note: t3.micro is eligible for the AWS free tier (750 hrs/month for
# the first 12 months). Larger instance types will incur compute charges.
variable "instance_type" {
  description = "EC2 instance type (default: t3.micro to minimize compute cost)"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "ID of the subnet where the EC2 instance will be launched (from Network module)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC for creating the compute security group (from Network module)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the root EBS volume (from KMS module)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance (e.g., '203.0.113.0/24'). No default - must be explicitly provided."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr must be a valid CIDR block (e.g., '10.0.0.0/24')."
  }
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources in this module"
  type        = map(string)
  default     = {}
}
