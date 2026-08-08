# Policy: Least-Privilege SSH Invariant
# Assert no security group allows 0.0.0.0/0 on port 22.
package main

import input

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_security_group"
  ingress := resource.values.ingress[_]
  ingress.from_port <= 22
  ingress.to_port >= 22
  cidr := ingress.cidr_blocks[_]
  cidr == "0.0.0.0/0"
  msg := sprintf("Security group '%s' allows SSH (port 22) from 0.0.0.0/0 - restrict to specific CIDR", [resource.address])
}
