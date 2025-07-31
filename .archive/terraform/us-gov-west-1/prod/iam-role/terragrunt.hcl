locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml")))
  )
}

terraform {
  source = "${path_relative_from_include()}//modules/iam-role"
}

include {
  path = find_in_parent_folders()
}

dependency "iam-policy" {
  config_path = "../iam-policy"
  mock_outputs = {
    arn = "aws_iam_policy.policy.arn"
  }
}

inputs = {
  role_name = "InstanceOpsRole-${local.env.name}"
  custom_role_policy_arns = [dependency.iam-policy.outputs.arn]
  tags      = merge(local.env.region_tags, local.env.tags, {})
}
