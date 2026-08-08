# Monitoring Module - Outputs

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.this.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for OS-level logs"
  value       = aws_cloudwatch_log_group.os_logs.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for security alert notifications"
  value       = aws_sns_topic.alerts.arn
}

output "config_rule_arn" {
  description = "ARN of the AWS Config rule for S3 bucket logging compliance"
  value       = aws_config_config_rule.s3_logging.arn
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret (KMS-encrypted)"
  value       = aws_secretsmanager_secret.this.arn
}
