// 提供商配置，设置AWS为提供商，指定区域和配置文件
provider "aws" {
  region  = "ap-southeast-1"
  profile = var.awsctl-profile
}

locals {
  workshop_name = "guance-eks"
  cluster_name  = "guance-eks-cluster"
}


// 定义可以被复用的标签
variable "tags" {
  type = map(any)
  default = {
    Terraform   = "true"
    Environment = "dev"
    TagKey      = "guance-workshop"
  }
}

variable "awsctl-profile" {}



// 创建VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  tags                 = merge(var.tags, { Name = "guance-workshop-vpc" })
  enable_dns_hostnames = true
}


// 创建互联网网关
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

// 创建公网路由表
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
}

// 在公网路由表中创建默认路由，并指向互联网网关
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

// 创建两个公网子网
resource "aws_subnet" "public_subnet" {
  count             = 2
  cidr_block        = "10.0.${count.index * 2}.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = count.index % 2 == 0 ? "ap-southeast-1a" : "ap-southeast-1b"


  tags = merge(var.tags, {
    Name                                          = "public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  })
}

// 将公网子网关联到公网路由表
resource "aws_route_table_association" "public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

// 创建私有路由表
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

// 创建默认NAT网关路由
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

// 创建两个私有子网
resource "aws_subnet" "private_subnet" {
  count             = 2
  cidr_block        = "10.0.${count.index * 2 + 1}.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = count.index % 2 == 0 ? "ap-southeast-1a" : "ap-southeast-1b"

  tags = merge(var.tags, {
    Name                                          = "private-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  })
}

// 将私有子网关联到私有路由表
resource "aws_route_table_association" "private_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

// 创建数据库用的安全组
resource "aws_security_group" "db_sg" {
  name_prefix = "db-"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

// 创建EIP资源
resource "aws_eip" "nat_eip" {
  tags = var.tags
}

// 创建NAT网关
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  depends_on    = [aws_internet_gateway.main]
  tags          = var.tags
}


// 在私有子网中创建数据库子网组
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "guanceworkshop-db-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id
  tags       = var.tags
}

// 创建一个为EKS集群服务的安全组
resource "aws_security_group" "eks" {
  name        = "guance-workshop"
  description = "Allow traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "World"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({
    Name = "guance-eks-workshop",
    ## "kubernetes.io/cluster/guance-eks-cluster" : "owned"
  }, var.tags)
}

// 创建一个允许SSH访问的安全组
resource "aws_security_group" "default_sg" {
  name_prefix = "guancewworkshop-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDS access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "redis access"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "guanceworkshop_default_sg" })
}

// 创建一个MySQL数据库实例
resource "aws_db_instance" "database" {
  allocated_storage    = 30
  storage_type         = "gp3"
  engine               = "mysql"
  engine_version       = "8.0.33"
  instance_class       = "db.t4g.medium"
  db_name              = "guancedb"
  username             = "admin"
  password             = "123425678"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot  = true // 注意这是一个示例，生产环境可能需要适当的快照策略
  vpc_security_group_ids = [aws_security_group.default_sg.id]
  tags                 = merge(var.tags, { Name = "guanceworkshop-db" })
}

// 创建ElastiCache子网组
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "guanceworkshop-redis-sg"
  subnet_ids = aws_subnet.private_subnet[*].id
}

// 创建一个Redis集群
resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "my-redis-cluster"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t4g.medium"
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = "default.redis7"
  security_group_ids = [aws_security_group.default_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
}

// 创建cloud9
resource "aws_cloud9_environment_ec2" "cloud9" {
  instance_type = "t3.small"
  name          = "guance-env-1"
  subnet_id     = aws_subnet.public_subnet[0].id
  tags          = merge(var.tags)
  
}

#terraform apply -auto-approve | grep "eks_alb_address\|rds_endpoint\|redis_endpoint"
