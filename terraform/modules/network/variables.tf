# Network Module - Variable Declarations

variable "vpc_cidr" {
  description = "CIDR block for the primary VPC (default: 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "management_subnet_cidr" {
  description = "CIDR block for the management subnet (default: 10.0.1.0/24)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "workload_subnet_cidr" {
  description = "CIDR block for the workload subnet (default: 10.0.2.0/24)"
  type        = string
  default     = "10.0.2.0/24"
}

# WARNING: Enabling Network Firewall incurs significant cost.
# AWS Network Firewall charges ~$0.395/hour (~$288/month) for the firewall
# endpoint plus data processing fees. Only enable for production or when
# testing firewall routing; leave disabled for cost-conscious learning.
variable "enable_network_firewall" {
  description = "Whether to provision AWS Network Firewall resources (WARNING: ~$0.395/hr cost). Default: false"
  type        = bool
  default     = false
}

variable "firewall_drop_port" {
  description = "TCP port number to block in the Network Firewall stateful rule group (default: 8080)"
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Map of tags to apply to all taggable resources in this module"
  type        = map(string)
  default     = {}
}
