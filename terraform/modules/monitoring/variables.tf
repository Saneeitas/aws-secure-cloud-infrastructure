# Monitoring Module - Variable Declarations

variable "s3_bucket_arn" {
  description = "ARN of the primary S3 bucket to monitor with CloudTrail data events"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the primary S3 bucket for Config rule evaluation"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting Secrets Manager secrets"
  type        = string
}

variable "ec2_instance_id" {
  description = "ID of the EC2 instance for log group targeting"
  type        = string
}

variable "notification_email" {
  description = "Email address for SNS alarm notifications (e.g., 'security-alerts@example.com'). No default - must be provided."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "notification_email must be a valid email address (e.g., 'user@example.com')."
  }
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources in this module"
  type        = map(string)
  default     = {}
}
