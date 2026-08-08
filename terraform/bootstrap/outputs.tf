# Bootstrap Module - Outputs
# Use these values to configure the S3 backend block in the dev environment.

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.state.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.lock.name
}
