variable "name" {
  description = "The name to apply to the external load balancer resources"
  type        = string
  default     = "bigbang-dev"
}

variable "vpc_id" {
  description = "The VPC where the load balancer should be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet ids to load balance"
  type        = list(string)
}

variable "node_port_health_checks" {
  description = "The node port to use for Istio health check traffic"
  type        = string
  default     = "30000"
}
variable "node_port_http" {
  description = "The node port to use for HTTP traffic"
  type        = string
  default     = "30001"
}

variable "node_port_https" {
  description = "The node port to use for HTTPS traffic"
  type        = string
  default     = "30002"
}

variable "node_port_sni" {
  description = "The node port to use for Istio SNI traffic"
  type        = string
  default     = "30003"
}

variable "tags" {
  description = "The tags to apply to resources"
  type        = map(string)
  default     = {}
}