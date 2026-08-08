# Compute Module - Main Configuration
# Launches an EC2 instance with an encrypted root volume, least-privilege
# IAM instance profile, and a restrictive security group.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Use SSM Parameter Store to always get the latest Amazon Linux 2023 AMI.
# This avoids hardcoding AMI IDs which are region-specific and change frequently.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# =============================================================================
# SECURITY GROUP
# Allows inbound SSH only from the explicitly specified CIDR block.
# This prevents accidental exposure to 0.0.0.0/0 by requiring the
# deployer to consciously define their trusted network range.
# =============================================================================

resource "aws_security_group" "compute" {
  name        = "${lookup(var.tags, "Project", "secure-infra")}-compute-sg"
  description = "Compute instance SG - SSH restricted to allowed CIDR only"
  vpc_id      = var.vpc_id

  # SSH access restricted to a specific CIDR - never use 0.0.0.0/0 for SSH
  # as it exposes the instance to brute-force attacks from the entire internet.
  ingress {
    description = "SSH from allowed CIDR only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-compute-sg"
  })
}

# =============================================================================
# IAM INSTANCE PROFILE - Least-privilege role
# The role grants only CloudWatch Logs publishing and SSM agent communication.
# No S3, EC2, or other broad permissions are included.
# =============================================================================

resource "aws_iam_role" "compute" {
  name = "${lookup(var.tags, "Project", "secure-infra")}-compute-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "compute_cloudwatch" {
  name = "cloudwatch-logs-publish"
  role = aws_iam_role.compute.id

  # CloudWatch Logs actions scoped to the deploying account.
  # CreateLogGroup uses a wildcard resource because the agent may need to
  # create log groups dynamically based on configuration.
  # Reference: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/iam-identity-based-access-control-cwl.html
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogsPublishing"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        # Wildcard on log-group name is required because the CloudWatch agent
        # creates log groups based on its JSON configuration file, and group
        # names are not known at deploy time.
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "compute_ssm" {
  name = "ssm-agent-communication"
  role = aws_iam_role.compute.id

  # SSM agent actions required for Session Manager and instance management.
  # ssmmessages:* and ec2messages:* use wildcard resources because the SSM
  # service creates dynamic channels that cannot be pre-determined.
  # Reference: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSSMAgentCommunication"
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Sid    = "AllowSSMMessaging"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        # Wildcard resource required - SSM messaging channels are dynamic
        # and their ARNs cannot be predicted at deploy time.
        # Reference: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-instance-profile.html
        Resource = "*"
      },
      {
        Sid    = "AllowEC2Messaging"
        Effect = "Allow"
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        # Wildcard resource required - EC2 message channels are service-managed.
        # Reference: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "compute" {
  name = "${lookup(var.tags, "Project", "secure-infra")}-compute-profile"
  role = aws_iam_role.compute.name

  tags = var.tags
}

# =============================================================================
# EC2 INSTANCE
# Encrypted root volume using the KMS key from the KMS module ensures
# data-at-rest protection for the OS disk.
# =============================================================================

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.compute.id]
  iam_instance_profile   = aws_iam_instance_profile.compute.name

  root_block_device {
    encrypted   = true
    kms_key_id  = var.kms_key_arn
    volume_type = "gp3"
    volume_size = 20
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 enforced - prevents SSRF credential theft
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "secure-infra")}-compute-instance"
  })
}
