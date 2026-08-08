# Network Module

## Purpose

Implements VPC segmentation with management and workload subnets, deny-by-default Network ACLs, restrictive security groups, VPC Flow Logs publishing to CloudWatch, and an optional AWS Network Firewall with custom stateful rules and multi-hop routing.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | CIDR block for the primary VPC |
| `management_subnet_cidr` | `string` | `"10.0.1.0/24"` | CIDR block for the management subnet |
| `workload_subnet_cidr` | `string` | `"10.0.2.0/24"` | CIDR block for the workload subnet |
| `enable_network_firewall` | `bool` | `false` | Enable Network Firewall (~$0.395/hr cost) |
| `firewall_drop_port` | `number` | `8080` | TCP port to block in firewall rules |
| `tags` | `map(string)` | `{}` | Tags to apply to all resources |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the primary VPC |
| `management_subnet_id` | ID of the management subnet |
| `workload_subnet_id` | ID of the workload subnet |
| `flow_log_group_name` | CloudWatch Log Group name for VPC Flow Logs |
