
## terraform output

output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis_cluster.cache_nodes[0].address
}

output "eks_name" {
  value = module.eks_cluster.cluster_name
}


output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks_cluster.cluster_security_group_id
}

output "config_map_aws_auth" {
  description = ""
  value       = module.eks_cluster.aws_auth_configmap_yaml
}

output "region" {
  description = "AWS region."
  value       = "sg"
}