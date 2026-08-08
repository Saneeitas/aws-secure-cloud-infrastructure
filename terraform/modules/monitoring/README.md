# Monitoring Module

## Purpose

Implements continuous security monitoring and automated compliance: CloudTrail with S3 data events, CloudWatch Log Group for OS-level logs, metric filter and alarm for SSH brute-force detection, SNS email notifications, AWS Config rule for S3 logging compliance with auto-remediation, and a KMS-encrypted Secrets Manager secret.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `s3_bucket_arn` | `string` | (required) | ARN of the primary S3 bucket for CloudTrail monitoring |
| `s3_bucket_name` | `string` | (required) | Name of the primary S3 bucket for Config rule |
| `kms_key_arn` | `string` | (required) | KMS key ARN for Secrets Manager encryption |
| `ec2_instance_id` | `string` | (required) | EC2 instance ID for log targeting |
| `notification_email` | `string` | (required) | Email for SNS alarm notifications (no default) |
| `tags` | `map(string)` | `{}` | Tags to apply to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `cloudtrail_trail_arn` | ARN of the CloudTrail trail |
| `cloudwatch_log_group_name` | CloudWatch Log Group name for OS logs |
| `sns_topic_arn` | ARN of the security alerts SNS topic |
| `config_rule_arn` | ARN of the S3 logging Config rule |
| `secret_arn` | ARN of the KMS-encrypted Secrets Manager secret |
