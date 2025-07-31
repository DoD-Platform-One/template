# Connects an Elastic Load Balancer to a pool of servers
# NOTE: RKE2 already sets the lifecycle of the auto scale group to ignore changes in load balancers and target groups
# See https://repo1.dso.mil/platform-one/distros/rancher-federal/rke2/rke2-aws-terraform/-/blob/master/modules/nodepool/main.tf#L113

resource "aws_autoscaling_attachment" "pool" {
  for_each               = toset(var.lb_target_group_arns)
  autoscaling_group_name = var.pool_asg_id
  lb_target_group_arn   = each.value
}