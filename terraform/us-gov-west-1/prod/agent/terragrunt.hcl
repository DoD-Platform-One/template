# This file sets up the RKE2 cluster generic agents in AWS using an autoscale group

locals {
  env = merge(
    yamldecode(file(find_in_parent_folders("region.yaml"))),
    yamldecode(file(find_in_parent_folders("env.yaml")))
  )
  image_id = run_cmd("sh", "-c", format("aws ec2 describe-images --owners 'aws-marketplace' --filters 'Name=product-code,Values=%s' --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' --output 'text'", local.env.image_product_code))
}

terraform {
  source = "git::https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform.git//modules/agent-nodepool?ref=v2.5.0"
}

include {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
    private_subnet_ids = ["mock_priv_subnet1", "mock_priv_subnet2", "mock_priv_subnet3"]
  }
}

dependency "server" {
  config_path = "../server"
  mock_outputs = {
    cluster_data = {
      name       = "mock"
      cluster_sg = "mock"
      server_url = "mock"
      token      = { bucket = "mock", bucket_arn = "mock", object = "", policy_document = "{}" }
    }
  }
}

dependency "elb" {
  config_path = "../elb"
  mock_outputs = {
    pool_sg_id = "mock_pool_sg_id"
  }
}

dependency "ssh" {
  config_path = "../ssh"
  mock_outputs = {
    public_key = "mock_public_key"
  }
}

inputs = {
  name               = "generic"
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnets            = dependency.vpc.outputs.private_subnet_ids
  ami                = local.image_id
  asg                = {
                         min : local.env.cluster.agent.replicas.min,
                         max : local.env.cluster.agent.replicas.max,
                         desired : local.env.cluster.agent.replicas.desired
                       }
  enable_ccm         = true
  enable_autoscaler  = true
  instance_type      = local.env.cluster.agent.type
  spot               = false
  download           = true
  rke2_version       = local.env.cluster.rke2_version
  iam_instance_profile = "InstanceOpsRole-${local.env.name}"

  extra_security_group_ids = [dependency.elb.outputs.pool_sg_id]
  ssh_authorized_keys = [dependency.ssh.outputs.public_key]

  block_device_mappings = {
    size = local.env.cluster.agent.storage.size
    encrypted = local.env.cluster.agent.storage.encrypted
    type = local.env.cluster.agent.storage.type
  }

  # Required output from rke2 server
  cluster_data = dependency.server.outputs.cluster_data

  pre_userdata = local.env.cluster.init_script

  tags = merge(local.env.region_tags, local.env.tags, {})
}
