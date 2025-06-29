data "aws_caller_identity" "current" {}

### eks
module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 19.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"
  vpc_id          = aws_vpc.main.id
  subnet_ids      = aws_subnet.private_subnet[*].id

  cluster_encryption_config             = {}
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access        = true
  cluster_enabled_log_types             = ["api", "audit", "authenticator"]
  tags                                  = var.tags
  cluster_additional_security_group_ids = [aws_security_group.eks.id]

  # Remote access cannot be specified with a launch template

  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    vpc_security_group_ids     = [aws_security_group.eks.id]
    iam_role_attach_cni_policy = true
  }


  # manage_aws_auth_configmap             = true
  #  aws_auth_roles = [
  #    {
  #      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/foo"
  #      username = "system:node:{{EC2PrivateDNSName}}"
  #      groups   = ["system:masters"]
  #    }
  #  ]

  eks_managed_node_groups = {
#        blue = {
#          min_size       = 1
#          max_size       = 3
#          desired_size   = 3
#          instance_types = ["c6i.2xlarge"]
#          #      capacity_type  = "SPOT"
#          labels = var.tags
#          taints = {
#          }
#          disk_size = 30
#          key_name  = "kevin-poc-sgs-1"
#          tags      = var.tags
#
#        }

    green = {
      min_size       = 1
      max_size       = 4
      desired_size   = 3
      instance_types = ["c6i.large"]
      #      capacity_type  = "SPOT"
      labels = var.tags
      taints = {
      }
      disk_size = 30
      key_name  = "kevin-poc-sgs-1"
      tags      = var.tags
    }
  }


}

module "lb_role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "${module.eks_cluster.cluster_name}_eks_lb"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks_cluster.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", "guance-eks-cluster"]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
      command     = "aws"
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
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
    value = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com/amazon/aws-load-balancer-controller" ##https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
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


#module "vpc_cni_irsa" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "~> 5.0"
#  role_name_prefix      = "VPC-CNI-IRSA"
#  attach_vpc_cni_policy = true
#  vpc_cni_enable_ipv6   = true
#  oidc_providers = {
#    main = {
#      provider_arn               = module.eks_cluster.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#    }
#  }
#  tags = var.tags
#}


module "eks-kubeconfig" {
  source  = "hyperbadger/eks-kubeconfig/aws"
  version = "2.0.0"
  # insert the 1 required variable here
  cluster_name = module.eks_cluster.cluster_name


  depends_on = [module.eks_cluster]

}


## addon 不能一起添加，容易报错
resource "aws_eks_addon" "addon-coredns" {
  cluster_name  = module.eks_cluster.cluster_name
  addon_name    = "coredns"
  addon_version = "v1.10.1-eksbuild.1" #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  ## resolve_conflicts_on_update = "OVERWRITE"
  tags = var.tags
  # service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
  depends_on = [module.eks_cluster]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = module.eks_cluster.cluster_name
  addon_name    = "vpc-cni"
  addon_version = "v1.12.6-eksbuild.2"

  # resolve_conflicts_on_update = "OVERWRITE"
  tags = var.tags
  # service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
  depends_on = [module.eks_cluster]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = module.eks_cluster.cluster_name
  addon_name   = "kube-proxy"
  # resolve_conflicts_on_update = "OVERWRITE"
  addon_version = "v1.27.1-eksbuild.1"
  tags          = var.tags
  # service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
  depends_on = [module.eks_cluster]
}


#####
#resource "null_resource" "kubectl" {
#  provisioner "local-exec" {
#    command = "aws eks --region ${aws.} update-kubeconfig --name ${local.cluster_name}"
#  }
#}
#locals {
#  kubeconfig = templatefile("templates/kubeconfig.tpl", {
#    kubeconfig_name                   = local.kubeconfig_name
#    endpoint                          = aws_eks_cluster.example.endpoint
#    cluster_auth_base64               = aws_eks_cluster.example.certificate_authority[0].data
#    aws_authenticator_command         = "aws-iam-authenticator"
#    aws_authenticator_command_args    = ["token", "-i", aws_eks_cluster.example.name]
#    aws_authenticator_additional_args = []
#    aws_authenticator_env_variables   = {}
#  })
#}
#output "kubeconfig" { value = local.kubeconfig }