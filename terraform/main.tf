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
  count         = 1
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  tags          = var.tags
}

resource "aws_eip" "nat_eip" {
  count = 1
  tags  = var.tags
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = aws_subnet.private_subnet[*].id
  tags       = var.tags
}

resource "aws_security_group" "eks" {
  name        = "${module.eks_cluster.oidc_provider} eks cluster"
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
    Name = "EKS prod",
    "kubernetes.io/cluster/guance-eks-cluster": "owned"
  }, var.tags)
}


module "eks_cluster" {
  source                    = "terraform-aws-modules/eks/aws"
  cluster_name              = "guance-eks-cluster"
  cluster_version           = "1.21"
  vpc_id                    = aws_vpc.main.id
  subnets                   = aws_subnet.private_subnet[*].id


  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_enabled_log_types = ["api", "audit", "authenticator"]
  tags                      = var.tags
  cluster_additional_security_group_ids = [aws_security_group.eks.id]


  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = 100
    instance_types         = ["t3.medium", "t3.large"]
    vpc_security_group_ids = [aws_security_group.eks.id]
  }

  eks_managed_node_groups = {
    blue = {

    }

    green = {
      min_size     = 1
      max_size     = 4
      desired_size = 3

      instance_types = ["t3.large"]
#      capacity_type  = "SPOT"
      labels = var.tags
      taints = {
      }
      tags = var.tags
    }
  }
}

module "lb_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${module.eks_cluster.cluster_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks_cluster.oidc_provider
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
#  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", "guance-eks-cluster"]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.oidc_provider
#    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.oidc_provider]
      command     = "aws"
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"= "aws-load-balancer-controller"
      "app.kubernetes.io/component"= "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "lb" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account
  ]

  set {
    name  = "region"
    value = "ap-southeast-1"
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.eu-west-2.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = module.eks_cluster.cluster_name
  }
}

#module "alb_ingress_controller" {
#  source = "terraform-aws-modules/alb-ingress-controller/aws"
#
#  cluster_name = module.eks_cluster.cluster_id
#  vpc_id       = s_vpc.main.idaw
#
#  alb_ingress_controller_namespace = "kube-system"
#  alb_ingress_controller_image_tag = "v1.1.8"
#  tags                             = var.tags
#}




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


#output "eks_alb_address" {
#  value = module.alb_ingress_controller.load_balancer_dns_name
#}

output "rds_endpoint" {
  value = aws_db_instance.database.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis_cluster.cluster_address
}



#terraform apply -auto-approve | grep "eks_alb_address\|rds_endpoint\|redis_endpoint"
