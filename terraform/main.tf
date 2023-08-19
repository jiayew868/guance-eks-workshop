provider "aws" {
  region = "ap-southeast-1" # 新加坡区域
}

variable "tags" {
  type = map(any)
  default = {
    Terraform   = "true"
    Environment = "dev"
    TagKey      = "guance-workshop"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = var.tags
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  cidr_block              = "10.0.${count.index * 2}.0/24"
  vpc_id                  = aws_vpc.main.id
  availability_zone       = count.index % 2 == 0 ? "ap-southeast-1a" : "ap-southeast-1b" # 分别在可用区1和2
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "public-subnet-${count.index + 1}"
  })
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  cidr_block        = "10.0.${count.index * 2 + 1}.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = count.index % 2 == 0 ? "ap-southeast-1a" : "ap-southeast-1b" # 分别在可用区1和2
  tags = merge(var.tags, {
    Name = "private-subnet-${count.index + 1}"
  })
}

resource "aws_security_group" "db_sg" {
  name_prefix = "db-"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = var.tags
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  tags          = var.tags
}

resource "aws_eip" "nat_eip" {
  count = 2
  tags  = var.tags
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id
  tags       = var.tags
}

resource "aws_security_group" "eks" {
  name        = "${var.env_name} eks cluster"
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
    Name = "EKS ${var.env_name}",
    "kubernetes.io/cluster/${local.eks_name}": "owned"
  }, var.tags)
}




module "eks_cluster" {
  source                    = "terraform-aws-modules/eks/aws"
  cluster_name              = "guance-eks-cluster"
  cluster_version           = "1.21"
  subnets                   = aws_subnet.private_subnet[*].id
  vpc_id                    = aws_vpc.main.id
  cluster_enabled_log_types = ["api", "audit", "authenticator"]
  tags                      = var.tags
}

module "alb_ingress_controller" {
  source = "terraform-aws-modules/alb-ingress-controller/aws"

  cluster_name = module.eks_cluster.cluster_id
  vpc_id       = aws_vpc.main.id

  alb_ingress_controller_namespace = "kube-system"
  alb_ingress_controller_image_tag = "v1.1.8"
  tags                             = var.tags
}


resource "aws_db_instance" "database" {
  allocated_storage    = 30
  storage_type         = "gp3"
  engine               = "mysql"
  engine_version       = "8.0.33"
  instance_class       = "db.t4g.medium"
  db_name              = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot  = true # 注意这是一个示例，生产环境可能需要适当的快照策略
  tags                 = var.tags
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id
}


resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "my-redis-cluster"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t4g.medium"
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = "default.redis7.0.cluster.on"
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
}


output "eks_alb_address" {
  value = module.alb_ingress_controller.load_balancer_dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis_cluster.cluster_address
}



#terraform apply -auto-approve | grep "eks_alb_address\|rds_endpoint\|redis_endpoint"
