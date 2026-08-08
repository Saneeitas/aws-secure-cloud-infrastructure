# S3 Module - Main Configuration
# Implements a fully hardened private S3 bucket with:
# - Public access blocked at all levels
# - Bucket policy restricting access to specific IAM principals
# - Versioning enabled for data protection
# - SSE-KMS encryption with bucket keys
# - Server access logging to a dedicated log bucket
# - Weekly inventory reporting

data "aws_caller_identity" "current" {}

# =============================================================================
# PRIMARY BUCKET
# =============================================================================

resource "aws_s3_bucket" "primary" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

# Block all public access - defense-in-depth control ensuring the bucket
# cannot be made public even if a permissive bucket policy is accidentally applied.
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning to protect against accidental deletion and provide
# an audit trail of object changes for forensic analysis.
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-KMS encryption with bucket keys enabled. Bucket keys reduce KMS API
# call costs by caching the data key at the bucket level rather than
# generating a unique data key per object.
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# Bucket policy implements least-privilege access:
# - Explicit deny for any principal NOT in the allowed list (defense-in-depth)
# - Explicit allow for only GetObject, PutObject, ListBucket actions
# This ensures that even if IAM policies grant broader S3 access,
# the bucket policy acts as a secondary authorization boundary.
resource "aws_s3_bucket_policy" "primary" {
  bucket = aws_s3_bucket.primary.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnauthorizedAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.primary.arn,
          "${aws_s3_bucket.primary.arn}/*"
        ]
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn" = var.allowed_principal_arns
          }
        }
      },
      {
        Sid    = "AllowAuthorizedAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principal_arns
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.primary.arn,
          "${aws_s3_bucket.primary.arn}/*"
        ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.primary]
}

# =============================================================================
# LOG BUCKET - Receives server access logs from the primary bucket
# =============================================================================

resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-access-logs"

  tags = merge(var.tags, {
    Name = "${var.bucket_name}-access-logs"
  })
}

# Block all public access on the log bucket as well.
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disable ACLs on the log bucket - use bucket ownership controls to ensure
# the bucket owner has full control over all log objects.
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Server access logging records all requests made to the primary bucket.
# Logs are essential for security auditing, access pattern analysis,
# and incident investigation.
resource "aws_s3_bucket_logging" "primary" {
  bucket = aws_s3_bucket.primary.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "access-logs/"
}

# =============================================================================
# INVENTORY - Weekly CSV inventory report for asset visibility
# =============================================================================

resource "aws_s3_bucket_inventory" "primary" {
  bucket = aws_s3_bucket.primary.id
  name   = "weekly-full-inventory"

  included_object_versions = "All"

  schedule {
    frequency = "Weekly"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = var.inventory_destination_bucket_arn
      prefix     = "inventory/${var.bucket_name}/"
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier",
    "BucketKeyStatus",
    "ChecksumAlgorithm",
    "ObjectAccessControlList",
    "ObjectOwner"
  ]
}
