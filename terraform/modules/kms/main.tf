# KMS Module - Main Configuration
# Manages a customer-managed KMS symmetric key with automatic rotation
# and a least-privilege key policy separating admin and usage permissions.

data "aws_caller_identity" "current" {}

# Customer-managed symmetric KMS key with annual rotation enabled.
# Rotation ensures that compromised key material has a limited blast radius
# because AWS automatically generates new backing key material each year.
resource "aws_kms_key" "this" {
  description         = var.description
  is_enabled          = true
  enable_key_rotation = true

  tags = var.tags
}

# Human-friendly alias so other modules and operators can reference
# the key by name rather than raw ARN/ID.
resource "aws_kms_alias" "this" {
  name          = "alias/${replace(lookup(var.tags, "Project", "secure-infra"), " ", "-")}-key"
  target_key_id = aws_kms_key.this.key_id
}

# Key policy separates administrative actions (key lifecycle management)
# from usage actions (encrypt/decrypt). This follows the principle of
# least privilege: administrators can manage the key but not use it for
# cryptographic operations, while usage principals can encrypt/decrypt
# but cannot modify or delete the key.
resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-policy-1"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Administrative actions: key lifecycle management only.
        # Granted to root account to allow IAM policy-based delegation.
        Sid    = "AllowKeyAdministration"
        Effect = "Allow"
        Principal = {
          AWS = var.admin_principal_arns
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        # Usage actions: cryptographic operations only.
        # These principals can encrypt/decrypt data but cannot modify
        # or delete the key itself.
        Sid    = "AllowKeyUsage"
        Effect = "Allow"
        Principal = {
          AWS = var.usage_principal_arns
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}
