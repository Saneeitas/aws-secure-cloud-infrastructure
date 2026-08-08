# KMS Module - Variable Declarations

variable "description" {
  description = "Description for the customer-managed KMS key"
  type        = string
  default     = "Customer-managed KMS key for encrypting sensitive resources"
}

variable "admin_principal_arns" {
  description = "List of IAM principal ARNs granted KMS administrative actions (key management)"
  type        = list(string)
}

variable "usage_principal_arns" {
  description = "List of IAM principal ARNs granted KMS usage actions (encrypt/decrypt)"
  type        = list(string)

  validation {
    condition     = length(var.usage_principal_arns) > 0
    error_message = "At least one principal ARN is required."
  }
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources in this module"
  type        = map(string)
  default     = {}
}
