# KMS Module

## Purpose

Manages a customer-managed AWS KMS symmetric key with automatic annual rotation and a least-privilege key policy. The key policy separates administrative actions (key lifecycle) from usage actions (encrypt/decrypt), ensuring no single principal has both capabilities.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `description` | `string` | `"Customer-managed KMS key for encrypting sensitive resources"` | Description for the KMS key |
| `admin_principal_arns` | `list(string)` | (required) | IAM principal ARNs granted key administration actions |
| `usage_principal_arns` | `list(string)` | (required) | IAM principal ARNs granted encrypt/decrypt actions |
| `tags` | `map(string)` | `{}` | Tags to apply to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `key_arn` | ARN of the customer-managed KMS key |
| `key_id` | ID of the customer-managed KMS key |
