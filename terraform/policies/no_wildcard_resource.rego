# Policy: No Wildcard Resource Invariant
# Assert no IAM policy statements use Resource: * without documented justification.
# Note: This policy checks inline IAM policies on roles. Key policies are excluded
# because KMS key policies use Resource: * to refer to the key itself (required by AWS).
package main

import input
import future.keywords.in

deny[msg] {
  resource := input.planned_values.root_module.child_modules[_].resources[_]
  resource.type == "aws_iam_role_policy"
  policy := json.unmarshal(resource.values.policy)
  statement := policy.Statement[_]
  statement.Resource == "*"
  statement.Effect == "Allow"
  # Exclude SSM messaging actions which require wildcard per AWS documentation
  not contains_ssm_actions(statement)
  msg := sprintf("IAM policy '%s' uses wildcard Resource '*' - document the justification or scope to specific ARNs", [resource.address])
}

contains_ssm_actions(statement) {
  action := statement.Action[_]
  startswith(action, "ssmmessages:")
}

contains_ssm_actions(statement) {
  action := statement.Action[_]
  startswith(action, "ec2messages:")
}
