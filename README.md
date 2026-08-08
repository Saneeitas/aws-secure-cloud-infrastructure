# aws-secure-cloud-infrastructure
Secure, monitored AWS environment (S3, VPC/Network Firewall, KMS, CloudTrail/Config) — built manually in the console, then codified as Terraform.

A hands-on AWS security engineering project covering data protection, network segmentation, encryption, and continuous monitoring — built and validated manually across four phases (S3 hardening, VPC/Network Firewall, KMS envelope encryption, CloudTrail/CloudWatch/Config), then re-implemented as reusable Terraform modules. Includes RBAC-style access testing, cost analysis via AWS Pricing Calculator, and a full security validation/test register.

Highlights: layered defense-in-depth (IAM + bucket policy + KMS key policy), AWS Network Firewall with custom routing, envelope encryption via the CLI, automated compliance remediation with AWS Config + Systems Manager, and infrastructure-as-code for the entire stack.
