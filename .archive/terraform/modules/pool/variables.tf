variable "name" {
  description = "The name to apply to resources"
  type        = string
  default     = "bigbang-dev"
}

variable "lb_target_group_arns" {
  description = "The load balancer's target group ARNs to attach to the autoscale group"
  type        = list(string)
}

variable "pool_asg_id" {
  description = "The pool's autoscale group ID"
  type        = string
}