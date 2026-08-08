# Compute Module

## Purpose

Launches an EC2 instance with a KMS-encrypted root volume, IMDSv2 enforced, a least-privilege IAM instance profile (CloudWatch Logs + SSM only), and a security group restricting SSH to an explicit CIDR block. Demonstrates secure compute provisioning with no over-permissive access.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance_type` | `string` | `"t3.micro"` | EC2 instance type (free tier eligible) |
| `subnet_id` | `string` | (required) | Subnet ID for instance placement |
| `vpc_id` | `string` | (required) | VPC ID for security group creation |
| `kms_key_arn` | `string` | (required) | KMS key ARN for EBS encryption |
| `allowed_ssh_cidr` | `string` | (required) | CIDR allowed SSH access (no default) |
| `tags` | `map(string)` | `{}` | Tags to apply to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | ID of the EC2 instance |
| `security_group_id` | ID of the compute security group |
