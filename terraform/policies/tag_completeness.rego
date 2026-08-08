# Policy: Tag Completeness Invariant
# Assert all taggable resources contain Project, Environment, Owner, ManagedBy tags.
package main

import input

required_tags := {"Project", "Environment", "Owner", "ManagedBy"}

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.values.tags != null
  tag := required_tags[_]
  not resource.values.tags[tag]
  msg := sprintf("Resource '%s' is missing required tag '%s'", [resource.address, tag])
}
