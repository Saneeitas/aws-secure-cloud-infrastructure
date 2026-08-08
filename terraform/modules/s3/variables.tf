# S3 Module - Variable Declarations

variable "bucket_name" {
  description = "Name for the primary S3 bucket (must be globally unique)"
  type        = string
}

variable "allowed_principal_arns" {
  description = "List of IAM principal ARNs allowed to access the S3 bucket. At least one is required."
  type        = list(string)

  validation {
    condition     = length(var.allowed_principal_arns) > 0
    error_message = "At least one IAM principal ARN must be provided."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for S3 server-side encryption (SSE-KMS)"
  type        = string
}

variable "inventory_destination_bucket_arn" {
  description = "ARN of the S3 bucket to receive inventory reports"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources in this module"
  type        = map(string)
  default     = {}
}
