
variable "region" {
  description = "Region to deploy"
  default     = "us-east-1"
}

variable "cluster_name" {
  default = "ggonda"
}

variable "node_count" {
  default = 3
}
