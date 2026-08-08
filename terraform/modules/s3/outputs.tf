# S3 Module - Outputs

output "bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.primary.id
}

output "bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "log_bucket_name" {
  description = "Name of the S3 access logging bucket"
  value       = aws_s3_bucket.logs.id
}
