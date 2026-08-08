# Policy: Versioning Invariant
# Assert the primary S3 bucket has versioning enabled.
package main

import input

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_s3_bucket_versioning"
  config := resource.values.versioning_configuration[_]
  config.status != "Enabled"
  msg := sprintf("S3 bucket versioning '%s' must have status set to 'Enabled'", [resource.address])
}
