# Policy: Cost-Gate Invariant
# Assert zero Network Firewall resources when enable_network_firewall is false.
package main

import input

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_networkfirewall_firewall"
  # If this resource exists in the plan, the firewall is enabled.
  # This policy only fires when the variable was supposed to be false
  # but firewall resources still appear.
  input.variables.enable_network_firewall.value == false
  msg := sprintf("Network Firewall resource '%s' exists but enable_network_firewall is false", [resource.address])
}

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_networkfirewall_firewall_policy"
  input.variables.enable_network_firewall.value == false
  msg := sprintf("Network Firewall policy '%s' exists but enable_network_firewall is false", [resource.address])
}
