# Bootstrap Module - Variable Declarations
# This module provisions the S3 bucket and DynamoDB table for Terraform remote state.

variable "state_bucket_name" {
  description = "Globally unique name for the S3 bucket used for Terraform state storage. No default - must be provided."
  type        = string

  validation {
    condition     = length(var.state_bucket_name) > 0
    error_message = "state_bucket_name must be a non-empty string."
  }
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources in this module"
  type        = map(string)
  default     = {}
}
