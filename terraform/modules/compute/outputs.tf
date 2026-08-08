# Compute Module - Outputs

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "security_group_id" {
  description = "ID of the compute security group"
  value       = aws_security_group.compute.id
}
