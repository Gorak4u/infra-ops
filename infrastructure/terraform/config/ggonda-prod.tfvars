
# Config for ggonda-prod (undefined)
region           = "us-east-1"
cluster_name     = "ggonda-prod"
environment      = "production"
node_count       = 3
instance_type    = "r5.2xlarge"
vpc_id           = "vpc-123"
subnet_ids       = ["subnet-123"]
security_groups  = ["sg-124"]
root_volume_size = 50
data_volume_size = 1000
data_volume_type = "gp3"

tags = {
  ManagedBy   = "OmniCloud"
  CostCenter  = "InfraOps"
  Application = "Cassandra"
}
