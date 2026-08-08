# AWS Secure Cloud Infrastructure - Terraform

A modular Terraform codebase implementing defense-in-depth security across four domains: data protection (S3), network security (VPC + Network Firewall), encryption (KMS), and monitoring/compliance (CloudTrail, CloudWatch, Config).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Dev Environment (Root)                         │
│                                                                   │
│  ┌─────────┐    ┌───────────┐    ┌─────────┐    ┌───────────┐  │
│  │   KMS   │───▶│    S3     │    │ Network │    │  Compute  │  │
│  │ Module  │    │  Module   │    │ Module  │    │  Module   │  │
│  └────┬────┘    └───────────┘    └────┬────┘    └─────┬─────┘  │
│       │                               │               │          │
│       │         ┌───────────┐         │               │          │
│       └────────▶│Monitoring │◀────────┘───────────────┘          │
│                 │  Module   │                                     │
│                 └───────────┘                                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐
│   Bootstrap (Standalone) │  ← Run separately for remote state
└─────────────────────────┘
```

**Module Dependencies:**
1. **KMS** → No dependencies (provision first)
2. **Network** → No dependencies (provision in parallel with KMS)
3. **S3** → Depends on KMS (key ARN for encryption)
4. **Compute** → Depends on KMS (EBS encryption) and Network (subnet/VPC)
5. **Monitoring** → Depends on S3, KMS, and Compute outputs

## Deployment Instructions

### Prerequisites

- Terraform >= 1.5
- AWS CLI configured with appropriate credentials
- An AWS account with permissions to create the resources

### Quick Start (Local State)

```bash
cd terraform/environments/dev

# Copy example variables and fill in your values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Opting Into Remote State (Optional)

1. Deploy the bootstrap module first:
   ```bash
   cd terraform/bootstrap
   terraform init
   terraform apply -var="state_bucket_name=your-unique-bucket-name"
   ```

2. Note the outputs (bucket name, DynamoDB table name).

3. Uncomment the backend block in `terraform/environments/dev/backend.tf` and fill in the values from step 2.

4. Re-initialize the dev environment to migrate state:
   ```bash
   cd terraform/environments/dev
   terraform init -migrate-state
   ```

## Cost Warning: Network Firewall

The `enable_network_firewall` variable defaults to `false`. When enabled, AWS Network Firewall charges approximately:
- **$0.395/hour** (~$288/month) per firewall endpoint
- **$0.065/GB** for data processed

Only enable this for production environments or when specifically testing firewall routing. For learning/portfolio purposes, keep it disabled.

## Ordered Destruction

To avoid dependency errors when destroying resources, follow this order:

```bash
cd terraform/environments/dev

# Option 1: Destroy everything at once (Terraform handles ordering)
terraform destroy

# Option 2: If you encounter dependency issues, destroy in reverse order:
terraform destroy -target=module.monitoring
terraform destroy -target=module.compute
terraform destroy -target=module.s3
terraform destroy -target=module.network
terraform destroy -target=module.kms
```

**Important:** The Bootstrap module manages its own state independently. Destroy it separately only if you want to remove remote state infrastructure:
```bash
cd terraform/bootstrap
terraform destroy
```

## Project Structure

```
terraform/
├── environments/
│   └── dev/              # Dev environment root module
│       ├── main.tf       # Module instantiation and provider config
│       ├── variables.tf  # All root-level variable declarations
│       ├── outputs.tf    # Root-level outputs
│       ├── versions.tf   # Provider and Terraform version constraints
│       ├── backend.tf    # Remote state config (commented out)
│       └── terraform.tfvars.example
├── modules/
│   ├── kms/              # Customer-managed KMS key with rotation
│   ├── s3/               # Hardened S3 bucket with logging & inventory
│   ├── network/          # VPC, subnets, NACLs, flow logs, firewall
│   ├── compute/          # EC2 with encrypted EBS and IAM profile
│   └── monitoring/       # CloudTrail, CloudWatch, Config, Secrets Manager
├── bootstrap/            # Standalone: S3 + DynamoDB for remote state
├── .gitignore
└── README.md             # This file
```

## Security Features

| Domain | Controls |
|--------|----------|
| Data Protection | S3 public access blocked, bucket policy, versioning, SSE-KMS, access logging, inventory |
| Network | VPC segmentation, deny-all NACLs, restrictive SGs, VPC Flow Logs, optional Network Firewall |
| Encryption | Customer-managed KMS key, annual rotation, least-privilege key policy |
| Compute | Encrypted root volume, IMDSv2 enforced, least-privilege IAM, restricted SSH |
| Monitoring | CloudTrail S3 data events, SSH brute-force alerting, Config compliance rules, auto-remediation |
