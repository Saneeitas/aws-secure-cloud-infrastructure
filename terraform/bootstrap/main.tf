# Bootstrap Module - Main Configuration
# Provisions the S3 bucket and DynamoDB table required for Terraform remote
# state with locking. Run this ONCE before enabling the S3 backend in the
# dev environment.
#
# Usage:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply -var="state_bucket_name=my-unique-tf-state-bucket"

terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# =============================================================================
# S3 STATE BUCKET
# Versioning protects against accidental state corruption - each state write
# creates a new version, allowing rollback if needed.
# =============================================================================

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  tags = merge(var.tags, {
    Name    = var.state_bucket_name
    Purpose = "Terraform remote state storage"
  })
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 encryption for state files at rest.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the state bucket - state files contain
# sensitive infrastructure details and must never be publicly accessible.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# DYNAMODB LOCK TABLE
# Prevents concurrent state modifications which could corrupt the state file.
# PAY_PER_REQUEST billing means zero cost when no locks are being acquired.
# =============================================================================

resource "aws_dynamodb_table" "lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    Name    = "terraform-state-lock"
    Purpose = "Terraform state locking"
  })
}
