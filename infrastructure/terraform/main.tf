
# ------------------------------------------------------------------
# Production-Grade Cassandra Infrastructure
# ------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

# --- Variables ---
variable "region" {}
variable "tags" { type = map(string) }
variable "cluster_name" {}
variable "environment" {}
variable "node_count" {}
variable "instance_type" {}
variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "security_groups" { type = list(string) }
variable "key_name" { default = "omnicloud-prod" }
variable "root_volume_size" { default = 50 }
variable "data_volume_size" { default = 1000 }
variable "data_volume_type" { default = "gp3" }

# --- Security ---
resource "aws_security_group" "cassandra" {
  name        = "${var.cluster_name}-sg"
  description = "Cassandra Ports"
  vpc_id      = var.vpc_id

  # Gossip
  ingress { from_port = 7000 to_port = 7001 protocol = "tcp" self = true }
  # CQL
  ingress { from_port = 9042 to_port = 9042 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] } # Tighten in prod
  # JMX
  ingress { from_port = 7199 to_port = 7199 protocol = "tcp" self = true }
  
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
}

# --- Compute ---
resource "aws_instance" "node" {
  count         = var.node_count
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = element(var.subnet_ids, count.index)
  vpc_security_group_ids = concat([aws_security_group.cassandra.id], var.security_groups)

  root_block_device {
    volume_size = var.root_volume_size
    encrypted   = true
  }

  ebs_optimized = true
  
  # User Data from global scripts
  user_data = file("${path.module}/../../scripts/bootstrap.sh")

  tags = {
    Name        = "${var.cluster_name}-${count.index + 1}"
    Role        = "cassandra_node"
    Cluster     = var.cluster_name
    Environment = var.environment
  }
}

# --- Storage ---
resource "aws_ebs_volume" "data" {
  count             = var.node_count
  availability_zone = aws_instance.node[count.index].availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  encrypted         = true
  tags = { Name = "${var.cluster_name}-data-${count.index + 1}" }
}

resource "aws_volume_attachment" "data" {
  count       = var.node_count
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data[count.index].id
  instance_id = aws_instance.node[count.index].id
}

output "node_ips" { value = aws_instance.node[*].private_ip }
