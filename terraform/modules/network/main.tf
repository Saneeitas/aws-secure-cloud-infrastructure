# Network Module - Main Configuration
# Implements VPC segmentation, deny-by-default NACLs, restrictive security groups,
# VPC Flow Logs, and an optional AWS Network Firewall with custom routing.

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# PRIMARY VPC - Management and Workload Segmentation
# =============================================================================

resource "aws_vpc" "primary" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-primary-vpc"
  })
}

# Management subnet - for bastion hosts, admin tooling, and jump boxes.
resource "aws_subnet" "management" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = var.management_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-management-subnet"
  })
}

# Workload subnet - for application instances and services.
resource "aws_subnet" "workload" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = var.workload_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-workload-subnet"
  })
}

# =============================================================================
# NETWORK ACLs - Deny-all by default
# NACLs provide a stateless firewall at the subnet level. By denying all
# traffic by default, we enforce explicit allow-listing of traffic patterns.
# This is a defense-in-depth control complementing security groups.
# =============================================================================

resource "aws_network_acl" "management" {
  vpc_id     = aws_vpc.primary.id
  subnet_ids = [aws_subnet.management.id]

  # Deny all inbound by default - explicit rules must be added for allowed traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Deny all outbound by default - explicit rules must be added for allowed traffic
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-management-nacl"
  })
}

resource "aws_network_acl" "workload" {
  vpc_id     = aws_vpc.primary.id
  subnet_ids = [aws_subnet.workload.id]

  # Deny all inbound by default
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Deny all outbound by default
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-workload-nacl"
  })
}

# =============================================================================
# SECURITY GROUPS - No ingress, allow-all egress
# Security groups are stateful firewalls at the instance level. Starting with
# no ingress rules enforces explicit rule creation for any inbound access.
# =============================================================================

resource "aws_security_group" "management" {
  name        = "${lookup(var.tags, "Project", "secure-infra")}-management-sg"
  description = "Management subnet security group - no ingress by default"
  vpc_id      = aws_vpc.primary.id

  # No ingress rules - all inbound traffic denied by default
  # Specific ingress must be added by consuming modules or additional rules

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-management-sg"
  })
}

resource "aws_security_group" "workload" {
  name        = "${lookup(var.tags, "Project", "secure-infra")}-workload-sg"
  description = "Workload subnet security group - no ingress by default"
  vpc_id      = aws_vpc.primary.id

  # No ingress rules - all inbound traffic denied by default

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-workload-sg"
  })
}

# =============================================================================
# VPC FLOW LOGS
# Flow Logs capture IP traffic metadata for the VPC, enabling visibility
# into network activity for security monitoring and incident response.
# =============================================================================

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs/${aws_vpc.primary.id}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-flow-logs"
  })
}

resource "aws_iam_role" "flow_logs" {
  name = "${lookup(var.tags, "Project", "secure-infra")}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "vpc-flow-logs-publish"
  role = aws_iam_role.flow_logs.id

  # Flow Logs requires CreateLogGroup, CreateLogStream, PutLogEvents, and
  # DescribeLogGroups/DescribeLogStreams. The wildcard on log-group resources
  # is required because the Flow Logs service creates log streams dynamically.
  # Reference: https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-cwl.html
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "primary" {
  vpc_id                   = aws_vpc.primary.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  log_destination_type     = "cloud-watch-logs"
  max_aggregation_interval = 60

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-flow-log"
  })
}

# =============================================================================
# OPTIONAL: AWS NETWORK FIREWALL
# Gated behind enable_network_firewall variable due to significant cost.
# Network Firewall charges ~$0.395/hour (~$288/month) per endpoint.
# =============================================================================

# Inspection VPC for Network Firewall - separate from workload VPC
# to enforce a clear security boundary for traffic inspection.
resource "aws_vpc" "firewall" {
  count = var.enable_network_firewall ? 1 : 0

  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-firewall-vpc"
  })
}

resource "aws_subnet" "firewall" {
  count = var.enable_network_firewall ? 1 : 0

  vpc_id            = aws_vpc.firewall[0].id
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-firewall-subnet"
  })
}

# Internet Gateway for firewall VPC (required for GWLB endpoint routing)
resource "aws_internet_gateway" "firewall" {
  count = var.enable_network_firewall ? 1 : 0

  vpc_id = aws_vpc.firewall[0].id

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-firewall-igw"
  })
}

# Stateful rule group: allows standard protocols and drops traffic on
# the configured drop port. This demonstrates defense-in-depth by
# explicitly defining allowed traffic patterns at the network level.
resource "aws_networkfirewall_rule_group" "stateful" {
  count = var.enable_network_firewall ? 1 : 0

  capacity = 100
  name     = "${lookup(var.tags, "Project", "secure-infra")}-stateful-rules"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<-EOT
        # Allow HTTP traffic
        pass tcp any any -> any 80 (msg:"Allow HTTP"; sid:1; rev:1;)
        # Allow HTTPS traffic
        pass tcp any any -> any 443 (msg:"Allow HTTPS"; sid:2; rev:1;)
        # Allow SSH traffic
        pass tcp any any -> any 22 (msg:"Allow SSH"; sid:3; rev:1;)
        # Allow ICMP (ping)
        pass icmp any any -> any any (msg:"Allow ICMP"; sid:4; rev:1;)
        # Drop traffic on configured port (default 8080)
        drop tcp any any -> any ${var.firewall_drop_port} (msg:"Drop blocked port"; sid:5; rev:1;)
      EOT
    }
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-stateful-rules"
  })
}

# Firewall policy ties rule groups together into an enforcement policy.
resource "aws_networkfirewall_firewall_policy" "this" {
  count = var.enable_network_firewall ? 1 : 0

  name = "${lookup(var.tags, "Project", "secure-infra")}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful[0].arn
    }
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-firewall-policy"
  })
}

# AWS Network Firewall - inspects all traffic routed through it.
# Cost: ~$0.395/hour per endpoint + data processing fees.
resource "aws_networkfirewall_firewall" "this" {
  count = var.enable_network_firewall ? 1 : 0

  name                = "${lookup(var.tags, "Project", "secure-infra")}-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this[0].arn
  vpc_id              = aws_vpc.firewall[0].id

  subnet_mapping {
    subnet_id = aws_subnet.firewall[0].id
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-network-firewall"
  })
}

# Route table implementing firewall routing - forces traffic through
# the Network Firewall's VPC endpoint for inspection before reaching
# the internet gateway.
resource "aws_route_table" "firewall_ingress" {
  count = var.enable_network_firewall ? 1 : 0

  vpc_id = aws_vpc.firewall[0].id

  # Route internet-bound traffic through the Network Firewall endpoint
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = element([for ep in tolist(aws_networkfirewall_firewall.this[0].firewall_status[0].sync_states) : ep.attachment[0].endpoint_id], 0)
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-firewall-ingress-rt"
  })
}

# Egress route table - sends return traffic from IGW through the firewall
resource "aws_route_table" "firewall_egress" {
  count = var.enable_network_firewall ? 1 : 0

  vpc_id = aws_vpc.firewall[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.firewall[0].id
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-firewall-egress-rt"
  })
}

resource "aws_route_table_association" "firewall_subnet" {
  count = var.enable_network_firewall ? 1 : 0

  subnet_id      = aws_subnet.firewall[0].id
  route_table_id = aws_route_table.firewall_egress[0].id
}
