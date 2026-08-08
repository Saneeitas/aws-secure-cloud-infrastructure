# Policy: S3 Public Access Invariant
# Assert all S3 bucket public access block flags are set to true.
package main

import input

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.values.block_public_acls != true
  msg := sprintf("S3 public access block '%s' must have block_public_acls set to true", [resource.address])
}

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.values.block_public_policy != true
  msg := sprintf("S3 public access block '%s' must have block_public_policy set to true", [resource.address])
}

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.values.ignore_public_acls != true
  msg := sprintf("S3 public access block '%s' must have ignore_public_acls set to true", [resource.address])
}

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.values.restrict_public_buckets != true
  msg := sprintf("S3 public access block '%s' must have restrict_public_buckets set to true", [resource.address])
}
