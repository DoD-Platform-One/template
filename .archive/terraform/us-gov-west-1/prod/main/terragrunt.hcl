# This file performs post-cluster actions, like downloading the kubeconfig
locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml")))
  )
}

terraform {
  source = "${path_relative_from_include()}//modules/s3"
}

include {
  path = find_in_parent_folders()
}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    kubeconfig_path = "kubeconfig_mock_path"
  }
}

inputs = {
  name = local.env.name
  kubeconfig_path = dependency.server.outputs.kubeconfig_path
}