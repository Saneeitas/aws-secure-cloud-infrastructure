# AWS Secure Cloud Infrastructure

Secure, monitored AWS environment (S3, VPC/Network Firewall, KMS, CloudTrail/Config) built manually in the console, then codified as both **Terraform** and **AWS CloudFormation** — two independent IaC implementations of the same architecture for side-by-side comparison.

## Scenario

As a **cloud security specialist at AnyCompany Financial Bank**, I was tasked by the Director of IT to secure the company's AWS Cloud resources. The bank operates locations throughout the country and provides checking/savings accounts, credit cards, loans, and investment products — all requiring the use of **personally identifiable information (PII)** such as account numbers, contact information, and personal IDs.

Key areas of the AWS infrastructure that needed to be secured include:
- **S3 buckets** storing sensitive financial data
- **The network** hosting web servers (VPC, subnets, firewalls)
- **Encryption keys** used to protect data at rest and in transit

The task was to secure these resources based on AWS best practices aligned with the **AWS Well-Architected Framework**, the **principle of least privilege**, and internal company IT standards.

### Access Testing Approach

Throughout the project, access to resources was tested using two test users:
- **Paulo** and **Mary** — members of the *Account Manager Group*. Paulo has more privileged access than Mary to certain resources, allowing verification that security mechanisms beyond IAM policies (bucket policies, KMS key policies, NACLs) are functioning correctly.
- **Sofia** — member of the *Financial Advisor Group*, used in the AWS KMS phase to test key usage permissions.

By comparing their access, we verify that defense-in-depth controls work independently of IAM.

### Solution Requirements

| Requirement | Description | Phase(s) |
|-------------|-------------|----------|
| **R1** | Design | Phase 2 |
| **R2** | Optimize cost | Phase 2 |
| **R3** | Restrict access | Phases 1, 2, 3 |
| **R4** | Enforce compliance | Phases 3, 4 |
| **R5** | Encrypt data | Phase 3 |
| **R6** | Withstand penetration testing | Phase 2 |
| **R7** | Monitor and log user activity | Phases 1, 4 |
| **R8** | Generate alert and change management notifications | Phase 4 |

### Project Phases

| Phase | Focus | Key Deliverables |
|-------|-------|-----------------|
| **Phase 1** | S3 Data Protection | Bucket policy, public access block, versioning, access logging, inventory |
| **Phase 2** | Network Security | VPC segmentation, NACLs, security groups, Network Firewall, flow logs |
| **Phase 3** | KMS Encryption | Customer-managed key, rotation, least-privilege key policy, envelope encryption |
| **Phase 4** | Monitoring & Compliance | CloudTrail, CloudWatch alerts, Config rules, auto-remediation, Secrets Manager |

## Project Overview

A hands-on AWS security engineering project covering data protection, network segmentation, encryption, and continuous monitoring. Built and validated manually across the four phases above, then re-implemented as reusable infrastructure-as-code in both Terraform and CloudFormation.

**Highlights:**
- Layered defense-in-depth (IAM + bucket policy + KMS key policy)
- AWS Network Firewall with custom routing (cost-gated behind a flag)
- Envelope encryption via customer-managed KMS keys with annual rotation
- Automated compliance remediation with AWS Config + Systems Manager
- SSH brute-force detection via CloudWatch metric filters and alarms
- RBAC-style access testing (Paulo, Mary, Sofia) validating least-privilege controls
- Two complete IaC implementations (Terraform + CloudFormation) for portfolio demonstration

## Repository Structure

```
.
├── terraform/                  # Terraform implementation
│   ├── environments/dev/       # Dev environment root module
│   ├── modules/                # Reusable child modules
│   │   ├── kms/                # KMS key, rotation, key policy
│   │   ├── s3/                 # Hardened S3 bucket, logging, inventory
│   │   ├── network/            # VPC, subnets, NACLs, SGs, Flow Logs, Firewall
│   │   ├── compute/            # EC2, encrypted EBS, IAM profile
│   │   └── monitoring/         # CloudTrail, CloudWatch, Config, Secrets Manager
│   ├── bootstrap/              # Standalone: S3 + DynamoDB for remote state
│   ├── policies/               # OPA/Conftest policy-as-code tests
│   ├── scripts/                # Validation scripts
│   └── README.md               # Terraform-specific docs
│
├── cloudformation/             # CloudFormation implementation
│   ├── templates/
│   │   ├── 01-s3.yaml          # S3 bucket, policy, versioning, logging, inventory
│   │   ├── 02-network.yaml     # VPC, subnets, NACLs, SGs, Flow Logs, Firewall
│   │   ├── 03-kms.yaml         # KMS key, rotation, key policy
│   │   ├── 04-compute.yaml     # EC2, encrypted EBS, IAM profile
│   │   └── 05-monitoring.yaml  # CloudTrail, CloudWatch, Config, Secrets Manager
│   ├── parameters/
│   │   └── dev.json.example    # Example parameter values
│   └── README.md               # CloudFormation-specific docs
│
└── README.md                   # This file
```

## Security Domains

| Domain | Controls |
|--------|----------|
| **Data Protection** | S3 public access blocked, least-privilege bucket policy, versioning, SSE-KMS with bucket keys, access logging, inventory |
| **Network Security** | VPC segmentation, deny-all NACLs, restrictive security groups, VPC Flow Logs, optional AWS Network Firewall with stateful rules |
| **Encryption** | Customer-managed KMS key, annual rotation, separated admin/usage key policy |
| **Compute** | Encrypted root volume, IMDSv2 enforced, least-privilege IAM (CW Logs + SSM only), restricted SSH |
| **Monitoring & Compliance** | CloudTrail S3 data events, SSH brute-force alerting, Config compliance rules, auto-remediation, KMS-encrypted Secrets Manager |

## Quick Start

### Terraform

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

See [`terraform/README.md`](terraform/README.md) for full deployment instructions, cost warnings, and destruction order.

### CloudFormation

```bash
cd cloudformation

# Deploy in dependency order:
# 1. KMS (no deps) → 2. Network (no deps) → 3. S3 → 4. Compute → 5. Monitoring

aws cloudformation deploy \
  --template-file templates/03-kms.yaml \
  --stack-name secure-infra-kms \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    Owner=security-team \
    AdminPrincipalArns="arn:aws:iam::123456789012:role/admin" \
    UsagePrincipalArns="arn:aws:iam::123456789012:role/app-role"
```

See [`cloudformation/README.md`](cloudformation/README.md) for full deployment commands, cross-stack references, and stack deletion order.

## Implementation Comparison

| Aspect | Terraform | CloudFormation |
|--------|-----------|----------------|
| State management | Remote (S3 + DynamoDB) or local | Managed by AWS (no state file) |
| Modularity | Child modules with outputs | Separate stacks with `Fn::ImportValue` |
| Conditionals | `count` / `for_each` | `Conditions` block |
| Validation | `terraform validate` + OPA policies | `aws cloudformation validate-template` |
| Drift detection | `terraform plan` | CloudFormation drift detection |
| Cost gating | `enable_network_firewall` variable | `DeployNetworkFirewall` condition parameter |
| Provider pinning | `~> 5.0` in versions.tf | Uses latest stable resource types |

## Cost Warning

AWS Network Firewall resources are **disabled by default** in both implementations due to significant cost:
- ~$0.395/hour (~$288/month) per firewall endpoint
- ~$0.065/GB for data processed

Enable only for production or when specifically testing firewall routing.

## Prerequisites

- AWS CLI configured with appropriate credentials
- **Terraform:** Terraform >= 1.5
- **CloudFormation:** AWS CLI v2
- An AWS account with permissions to create the resources

## License

This project is for portfolio/educational purposes.
