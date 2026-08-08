# Policy: KMS Rotation Invariant
# Assert all KMS keys have automatic rotation enabled.
package main

import input

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_kms_key"
  resource.values.enable_key_rotation != true
  msg := sprintf("KMS key '%s' must have enable_key_rotation set to true", [resource.address])
}
