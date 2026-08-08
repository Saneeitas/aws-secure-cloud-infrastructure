# Dev Environment - Root-Level Outputs
# Surfaces key resource identifiers for quick reference after apply.

output "s3_bucket_name" {
  description = "Name of the primary hardened S3 bucket"
  value       = module.s3.bucket_name
}

output "vpc_id" {
  description = "ID of the primary VPC created by the Network module"
  value       = module.network.vpc_id
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS encryption key"
  value       = module.kms.key_arn
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail monitoring S3 data events"
  value       = module.monitoring.cloudtrail_trail_arn
}

output "ec2_instance_id" {
  description = "ID of the EC2 compute instance with encrypted root volume"
  value       = module.compute.instance_id
}
