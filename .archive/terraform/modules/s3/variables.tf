variable "name" {
  description = "The name of the SSH key"
  type        = string
  default     = "bigbang-dev"
}

variable "kubeconfig_path" {
  description = "Remote path to kubeconfig"
  type        = string
}

variable "private_key_path" {
  description = "Local path to SSH private key"
  type        = string
  default     = "~/.ssh"
}