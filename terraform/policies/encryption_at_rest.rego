# Policy: Encryption-at-Rest Invariant
# Assert EC2 root volumes and Secrets Manager secrets reference a KMS key ARN.
package main

import input

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_instance"
  block := resource.values.root_block_device[_]
  block.encrypted != true
  msg := sprintf("EC2 instance '%s' must have an encrypted root block device", [resource.address])
}

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_instance"
  block := resource.values.root_block_device[_]
  block.kms_key_id == ""
  msg := sprintf("EC2 instance '%s' must specify a KMS key for root volume encryption", [resource.address])
}

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_secretsmanager_secret"
  resource.values.kms_key_id == ""
  msg := sprintf("Secrets Manager secret '%s' must be encrypted with a KMS key", [resource.address])
}
