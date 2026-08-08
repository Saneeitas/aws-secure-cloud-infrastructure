# Network Module - Outputs

output "vpc_id" {
  description = "ID of the primary VPC"
  value       = aws_vpc.primary.id
}

output "management_subnet_id" {
  description = "ID of the management subnet"
  value       = aws_subnet.management.id
}

output "workload_subnet_id" {
  description = "ID of the workload subnet"
  value       = aws_subnet.workload.id
}

output "flow_log_group_name" {
  description = "Name of the CloudWatch Log Group receiving VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs.name
}
