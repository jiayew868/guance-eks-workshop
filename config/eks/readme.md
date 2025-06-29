


## eks 构建
export AWS_REGION=ap-southeast-1
export CLUSTER_NAME=eks-workshop01


eksctl upgrade cluster --config-file cluster.yaml

kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

eksctl utils update-kube-proxy --cluster=<clusterName>


eksctl create cluster -f cluster.yaml

eksctl utils write-kubeconfig --cluster=eks-workshop03 --region=ap-southeast-1

eksctl utils update-kube-proxy --cluster=eks-workshop03 --region=ap-southeast-1  --approve
eksctl utils update-aws-node --cluster=eks-workshop03 --region=ap-southeast-1 --approve
eksctl utils update-coredns --cluster=${CLUSTER_NAME} --region=${AWS_REGION} --approve
eksctl utils associate-iam-oidc-provider --approve --cluster ${CLUSTER_NAME}  --region ${AWS_REGION}
https://oidc.eks.ap-southeast-1.amazonaws.com/id/DEBA4E2B5F3886B2FC0EE7352A1B9F82

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json



aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json \
    --region=ap-southeast-1 \
    --profile=sg

拿到
arn:aws:iam::964479626419:policy/AWSLoadBalancerControllerIAMPolicy


eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME}  \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole_${CLUSTER_NAME} \
  --attach-policy-arn=arn:aws:iam::964479626419:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --override-existing-serviceaccounts \

kubectl apply -f rbac-role.yaml --cluster=eks-workshop03.ap-southeast-1.eksctl.io

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set region=${AWS_REGION} \
  --set vpcId=vpc-05b22a6d04b23743e \
  --set serviceAccount.name=aws-load-balancer-controller


## ebs
eksctl create iamserviceaccount \
--name ebs-csi-controller-sa \
--namespace kube-system \
--cluster ${CLUSTER_NAME} \
--role-name AmazonEKS_EBS_CSI_DriverRole \
--role-only \
--attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
--override-existing-serviceaccounts \
--approve

aws iam attach-role-policy \
--policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
--role-name AmazonEKS_EBS_CSI_DriverRole --profile sg

eksctl create addon  \
--name aws-ebs-csi-driver \
--cluster ${CLUSTER_NAME} \
--service-account-role-arn arn:aws:iam::964479626419:role/AmazonEKS_EBS_CSI_DriverRole
--force

eksctl create addon --name aws-ebs-csi-driver --cluster  ${CLUSTER_NAME} --service-account-role-arn arn:aws:iam::964479626419:role/AmazonEKS_EBS_CSI_DriverRole --force

## 重启 ebs csi controller 'ebs-csi-controller-'
kubectl delete pod ebs-csi-controller-5677df7645-pzlb6 -n kube-system

## vpc-cni addon
eksctl create iamserviceaccount \
--name aws-node \
--namespace kube-system \
--cluster ${CLUSTER_NAME} \
--role-name AmazonEKSVPCCNIRole \
--attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
--override-existing-serviceaccounts \
--approve

arn:aws:iam::964479626419:role/AmazonEKSVPCCNIRole

kubectl describe daemonset aws-node --namespace kube-system | grep amazon-k8s-cni: | cut -d : -f 3
v1.12.6

eksctl create addon --name vpc-cni --cluster  ${CLUSTER_NAME} --service-account-role-arn arn:aws:iam::964479626419:role/AmazonEKSVPCCNIRole --force

## efs csi


## eks-pod-identity-agent
https://github.com/eksctl-io/eksctl/blob/main/examples/39-pod-identity-association.yaml
https://chariotsolutions.com/blog/post/hands-on-with-eks-pod-identity/


## Karpenter
https://repost.aws/knowledge-center/eks-install-karpenter
https://aws.amazon.com/cn/blogs/china/introducing-karpenter-an-open-source-high-performance-kubernetes-cluster-autoscaler/
https://catalog.workshops.aws/karpenter/en-US/install-karpenter

TEMPOUT=$(mktemp)

curl -fsSL https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
--stack-name "Karpenter-${CLUSTER_NAME}" \
--template-file "${TEMPOUT}" \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides "ClusterName=${CLUSTER_NAME}"

eksctl create iamidentitymapping \
--username system:node:{{EC2PrivateDNSName}} \
--cluster "${CLUSTER_NAME}" \
--arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
--group system:bootstrappers \
--group system:nodes

eksctl create iamserviceaccount \
--cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
--role-name "${CLUSTER_NAME}-karpenter" \
--attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
--role-only \
--approve

export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"


KARPENTER_VERSION=$(curl -sL "https://api.github.com/repos/aws/karpenter/releases/latest" | jq -r ".tag_name") && echo "Karpenter's Latest release version: $KARPENTER_VERSION" && export KARPENTER_VERSION


echo Your Karpenter version is: $KARPENTER_VERSION
docker logout public.ecr.aws
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version ${KARPENTER_VERSION} --namespace karpenter --create-namespace \
--set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
--set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME} \
--set settings.clusterName=${CLUSTER_NAME} \
--set settings.clusterEndpoint=${CLUSTER_ENDPOINT} \
--set settings.interruptionQueueName=${CLUSTER_NAME} \
--set settings.featureGates.drift=true \
--wait

kubectl scale -n other deployment/inflate --replicas 5

```shell
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot","on-demand"]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ["ap-southeast-1a", "ap-southeast-1b"]  
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["1"]
      nodeClassRef:
        name: default
  limits:
    cpu: 20
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h # 30 * 24h = 720h
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2 # Amazon Linux 2
  role: "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}" # replace with your cluster name
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}" # replace with your cluster name
EOF
```






## 检查ebs addon
eksctl get addon --name aws-ebs-csi-driver --cluster ${CLUSTER_NAME}
eksctl get addons --cluster ${CLUSTER_NAME}

##demo check ebs cis
cd config/eks/aws-ebs-csi-driver/examples/kubernetes/dynamic-provisioning
kubectl apply -f specs/

kubectl describe storageclass ebs-sc



## 检查eks addon有那些
eksctl utils describe-addon-versions --kubernetes-version 1.28 | grep AddonName

















