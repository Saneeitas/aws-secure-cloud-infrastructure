# S3 Module

## Purpose

Provisions a fully hardened private S3 bucket implementing defense-in-depth data protection: public access blocked, bucket policy with explicit deny for unauthorized principals, versioning, SSE-KMS encryption with bucket keys, server access logging to a dedicated log bucket, and weekly inventory reporting.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `bucket_name` | `string` | (required) | Globally unique name for the primary S3 bucket |
| `allowed_principal_arns` | `list(string)` | (required) | IAM principal ARNs allowed bucket access (min 1) |
| `kms_key_arn` | `string` | (required) | KMS key ARN for SSE-KMS encryption |
| `inventory_destination_bucket_arn` | `string` | (required) | S3 bucket ARN for inventory report delivery |
| `tags` | `map(string)` | `{}` | Tags to apply to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the primary S3 bucket |
| `bucket_arn` | ARN of the primary S3 bucket |
| `log_bucket_name` | Name of the access logging bucket |
