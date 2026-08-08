# AWS Secure Cloud Infrastructure — CloudFormation

An equivalent implementation of the Terraform-based security architecture using AWS CloudFormation. Both implementations produce the same set of resources and security controls, allowing side-by-side comparison of the two IaC approaches.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Stack Dependencies                          │
│                                                                    │
│  03-kms ──────┐                                                   │
│               ├──▶ 01-s3                                          │
│               │                                                    │
│  02-network ──┼──▶ 04-compute                                     │
│               │                                                    │
│  01-s3 ───────┼──▶ 05-monitoring                                  │
│  03-kms ──────┤                                                   │
│  04-compute ──┘                                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Deployment Order

Stacks must be deployed in this order due to cross-stack references (`Fn::ImportValue`):

1. **03-kms** — No dependencies (deploy first)
2. **02-network** — No dependencies (can deploy in parallel with 03-kms)
3. **01-s3** — Depends on 03-kms (imports KMS key ARN via parameter)
4. **04-compute** — Depends on 02-network and 03-kms (imports VPC, subnet, KMS key)
5. **05-monitoring** — Depends on 01-s3, 03-kms, and 04-compute (imports bucket, key, instance)

## Deploy Commands

Replace parameter values with your actual values. The examples below use stack names that match the `parameters/dev.json.example` file.

### 1. Deploy KMS Stack

```bash
aws cloudformation deploy \
  --template-file templates/03-kms.yaml \
  --stack-name secure-infra-kms \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=aws-secure-infrastructure \
    Environment=dev \
    Owner=security-team \
    AdminPrincipalArns="arn:aws:iam::123456789012:role/admin" \
    UsagePrincipalArns="arn:aws:iam::123456789012:role/app-role"
```

### 2. Deploy Network Stack

```bash
aws cloudformation deploy \
  --template-file templates/02-network.yaml \
  --stack-name secure-infra-network \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=aws-secure-infrastructure \
    Environment=dev \
    Owner=security-team \
    DeployNetworkFirewall=false
```

### 3. Deploy S3 Stack

```bash
# Get the KMS key ARN from the kms stack output
KMS_KEY_ARN=$(aws cloudformation describe-stacks \
  --stack-name secure-infra-kms \
  --query 'Stacks[0].Outputs[?OutputKey==`KeyArn`].OutputValue' \
  --output text)

aws cloudformation deploy \
  --template-file templates/01-s3.yaml \
  --stack-name secure-infra-s3 \
  --parameter-overrides \
    ProjectName=aws-secure-infrastructure \
    Environment=dev \
    Owner=security-team \
    BucketName=my-org-secure-data-dev \
    KmsKeyArn="$KMS_KEY_ARN" \
    AllowedPrincipalArns="arn:aws:iam::123456789012:role/app-role" \
    InventoryDestinationBucketArn="arn:aws:s3:::my-org-inventory-bucket"
```

### 4. Deploy Compute Stack

```bash
aws cloudformation deploy \
  --template-file templates/04-compute.yaml \
  --stack-name secure-infra-compute \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=aws-secure-infrastructure \
    Environment=dev \
    Owner=security-team \
    NetworkStackName=secure-infra-network \
    KmsStackName=secure-infra-kms \
    AllowedSshCidr="203.0.113.0/24"
```

### 5. Deploy Monitoring Stack

```bash
aws cloudformation deploy \
  --template-file templates/05-monitoring.yaml \
  --stack-name secure-infra-monitoring \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=aws-secure-infrastructure \
    Environment=dev \
    Owner=security-team \
    S3StackName=secure-infra-s3 \
    KmsStackName=secure-infra-kms \
    ComputeStackName=secure-infra-compute \
    NotificationEmail="security-alerts@example.com"
```

## Cost Warning: Network Firewall

The `DeployNetworkFirewall` parameter in `02-network.yaml` defaults to `"false"`. When set to `"true"`, AWS Network Firewall charges approximately:

- **$0.395/hour** (~$288/month) per firewall endpoint
- **$0.065/GB** for data processed

Only enable for production environments or when specifically testing firewall routing.

## Stack Deletion Order

Delete stacks in **reverse** order of creation. CloudFormation cannot delete a stack whose exports are still being imported by another stack.

```bash
# 1. Delete monitoring first (imports from s3, kms, compute)
aws cloudformation delete-stack --stack-name secure-infra-monitoring
aws cloudformation wait stack-delete-complete --stack-name secure-infra-monitoring

# 2. Delete compute (imports from network, kms)
aws cloudformation delete-stack --stack-name secure-infra-compute
aws cloudformation wait stack-delete-complete --stack-name secure-infra-compute

# 3. Delete S3 (imports from kms via parameter — no Fn::ImportValue, but logical dependency)
aws cloudformation delete-stack --stack-name secure-infra-s3
aws cloudformation wait stack-delete-complete --stack-name secure-infra-s3

# 4. Delete network and kms (no remaining importers)
aws cloudformation delete-stack --stack-name secure-infra-network
aws cloudformation delete-stack --stack-name secure-infra-kms
aws cloudformation wait stack-delete-complete --stack-name secure-infra-network
aws cloudformation wait stack-delete-complete --stack-name secure-infra-kms
```

**Note:** If S3 buckets contain objects, you must empty them before stack deletion:
```bash
aws s3 rm s3://my-org-secure-data-dev --recursive
aws s3 rm s3://my-org-secure-data-dev-access-logs --recursive
```

## Cross-Stack References

| Export Name Pattern | Source Stack | Consumed By |
|---|---|---|
| `${StackName}-KeyArn` | 03-kms | 04-compute, 05-monitoring |
| `${StackName}-KeyId` | 03-kms | — |
| `${StackName}-VpcId` | 02-network | 04-compute |
| `${StackName}-WorkloadSubnetId` | 02-network | 04-compute |
| `${StackName}-BucketArn` | 01-s3 | 05-monitoring |
| `${StackName}-BucketName` | 01-s3 | 05-monitoring |
| `${StackName}-InstanceId` | 04-compute | 05-monitoring |
| `${StackName}-TrailArn` | 05-monitoring | — |
| `${StackName}-SnsTopicArn` | 05-monitoring | — |

## Validating Templates

```bash
# Validate each template before deploying
for f in templates/*.yaml; do
  echo "Validating $f..."
  aws cloudformation validate-template --template-body "file://$f"
done
```

## Project Structure

```
cloudformation/
├── templates/
│   ├── 01-s3.yaml          — S3 bucket, policy, versioning, logging, inventory
│   ├── 02-network.yaml     — VPC, subnets, NACLs, SGs, Flow Logs, Network Firewall
│   ├── 03-kms.yaml         — KMS key, rotation, key policy
│   ├── 04-compute.yaml     — EC2, IAM profile, security group
│   └── 05-monitoring.yaml  — CloudTrail, CloudWatch, SNS, Config, Secrets Manager
├── parameters/
│   └── dev.json.example    — Example parameter values for all templates
└── README.md               — This file
```

## Comparison with Terraform Implementation

| Aspect | Terraform (`/terraform`) | CloudFormation (`/cloudformation`) |
|--------|--------------------------|-------------------------------------|
| State | Remote (S3 + DynamoDB) or local | Managed by AWS (no state file) |
| Dependencies | Implicit via module outputs | Explicit via Fn::ImportValue |
| Conditionals | `count` / `for_each` | `Conditions` block |
| Validation | `terraform validate` + OPA | `aws cloudformation validate-template` |
| Drift detection | `terraform plan` | CloudFormation drift detection |
| Modularity | Child modules | Separate stacks with exports |
