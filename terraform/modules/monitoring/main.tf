# Monitoring Module - Main Configuration
# Implements CloudTrail, CloudWatch alerting, AWS Config rules with
# auto-remediation, and Secrets Manager for continuous security monitoring.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# CLOUDTRAIL - S3 Data Event Logging
# Captures all S3 API activity on the primary bucket for forensic analysis
# and compliance evidence. Data events provide object-level visibility.
# =============================================================================

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${lookup(var.tags, "Project", "secure-infra")}"
  retention_in_days = 90

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-cloudtrail-logs"
  })
}

resource "aws_iam_role" "cloudtrail" {
  name = "${lookup(var.tags, "Project", "secure-infra")}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_logs" {
  name = "cloudtrail-cloudwatch-logs"
  role = aws_iam_role.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailLogsPublishing"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# S3 bucket for CloudTrail logs storage
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${lookup(var.tags, "Project", "secure-infra")}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-cloudtrail-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "this" {
  name                          = "${lookup(var.tags, "Project", "secure-infra")}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn

  # S3 data events capture object-level API activity (GetObject, PutObject, etc.)
  # for the monitored bucket, providing full visibility into data access patterns.
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${var.s3_bucket_arn}/"]
    }
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-trail"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# =============================================================================
# CLOUDWATCH LOG GROUP - OS-level logs from EC2 instance
# 90-day retention for compliance and incident response timelines.
# =============================================================================

resource "aws_cloudwatch_log_group" "os_logs" {
  name              = "/aws/ec2/${lookup(var.tags, "Project", "secure-infra")}/os-logs"
  retention_in_days = 90

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-os-logs"
  })
}

# =============================================================================
# METRIC FILTER AND ALARM - SSH Brute Force Detection
# Detects failed SSH login attempts indicating potential brute-force attacks.
# Triggers an alarm when count exceeds threshold within evaluation period.
# =============================================================================

resource "aws_cloudwatch_log_metric_filter" "ssh_failures" {
  name           = "${lookup(var.tags, "Project", "secure-infra")}-ssh-failures"
  pattern        = "\"Invalid user\" OR \"Failed password\""
  log_group_name = aws_cloudwatch_log_group.os_logs.name

  metric_transformation {
    name      = "SSHFailedLogins"
    namespace = "${lookup(var.tags, "Project", "secure-infra")}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ssh_brute_force" {
  alarm_name          = "${lookup(var.tags, "Project", "secure-infra")}-ssh-brute-force"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SSHFailedLogins"
  namespace           = "${lookup(var.tags, "Project", "secure-infra")}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggers when more than 5 failed SSH login attempts occur within 5 minutes"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = var.tags
}

# =============================================================================
# SNS TOPIC - Alarm Notifications
# =============================================================================

resource "aws_sns_topic" "alerts" {
  name = "${lookup(var.tags, "Project", "secure-infra")}-security-alerts"

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-security-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# =============================================================================
# AWS CONFIG RULE - S3 Bucket Logging Compliance
# Evaluates whether the primary S3 bucket has logging enabled.
# Auto-remediation re-enables logging if it is ever disabled.
# =============================================================================

resource "aws_config_config_rule" "s3_logging" {
  name = "s3-bucket-logging-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LOGGING_ENABLED"
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
    compliance_resource_id    = var.s3_bucket_name
  }

  tags = var.tags
}

# Auto-remediation using SSM Automation to re-enable S3 bucket logging
# when the Config rule evaluates as NON_COMPLIANT. This implements
# automated security drift correction.
resource "aws_config_remediation_configuration" "s3_logging" {
  config_rule_name = aws_config_config_rule.s3_logging.name
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-ConfigureS3BucketLogging"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.config_remediation.arn
  }

  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }

  parameter {
    name         = "TargetBucket"
    static_value = "${var.s3_bucket_name}-access-logs"
  }

  parameter {
    name         = "TargetPrefix"
    static_value = "access-logs/"
  }

  automatic                  = true
  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60
}

resource "aws_iam_role" "config_remediation" {
  name = "${lookup(var.tags, "Project", "secure-infra")}-config-remediation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "config_remediation" {
  name = "config-remediation-s3-logging"
  role = aws_iam_role.config_remediation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutBucketLogging",
          "s3:GetBucketLogging"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}-access-logs"
        ]
      }
    ]
  })
}

# =============================================================================
# SECRETS MANAGER - Encrypted secret demonstrating encryption-at-rest
# Uses the KMS key from the KMS module to encrypt the secret value,
# demonstrating integration between KMS and Secrets Manager for
# centralized encryption key management.
# =============================================================================

resource "aws_secretsmanager_secret" "this" {
  name       = "${lookup(var.tags, "Project", "secure-infra")}/demo-secret"
  kms_key_id = var.kms_key_arn

  # Encryption-at-rest using customer-managed KMS key provides:
  # 1. Full control over key lifecycle and rotation
  # 2. Audit trail via CloudTrail for all decrypt operations
  # 3. Ability to revoke access by disabling or deleting the key

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-demo-secret"
  })
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  # Placeholder value demonstrating encryption-at-rest.
  # In production, this would be populated by an external process or CI/CD pipeline.
  secret_string = jsonencode({
    username = "demo-user"
    password = "REPLACE_WITH_ACTUAL_SECRET_VALUE"
    note     = "This is a placeholder demonstrating KMS-encrypted secrets storage"
  })
}
