locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml")))
  )
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.env.region}"
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in S3 bucket
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    encrypt = true
    key     = format("%s/terraform.tfstate", path_relative_to_include())
    bucket  = "${local.env.name}-terraform-state"
    region  = local.env.region
  }
}