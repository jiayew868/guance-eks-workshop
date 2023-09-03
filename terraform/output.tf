
## terraform output


output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis_cluster.cache_nodes[0].address
}