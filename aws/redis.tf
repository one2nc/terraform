output "redis-address" {
  value = aws_elasticache_cluster.cache.*.cluster_id
}

variable "cache_node_type" {
  type = string
}

variable "num_cache_nodes" {
  type = number
}

resource "aws_security_group" "cache" {
  vpc_id      = aws_vpc.vpc.id
  name        = "cache-sg"
  description = "Redis Security Group"
  ingress {
    from_port   = 6379
    protocol    = "tcp"
    to_port     = 6379
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_elasticache_subnet_group" "cache" {
  name        = "cache"
  description = "Redis Subnet Group"
  subnet_ids  = aws_subnet.private.*.id
}

resource "aws_elasticache_cluster" "cache" {
  cluster_id           = aws_vpc.vpc.id
  engine               = "redis"
  node_type            = var.cache_node_type
  port                 = 6379
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = "default.redis5.0"
  security_group_ids   = [aws_security_group.cache.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache.name
}
