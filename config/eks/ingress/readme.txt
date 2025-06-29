
export AWS_REGION=cn-northwest-1
export CLUSTER_NAME=eks-workshop02

eksctl utils associate-iam-oidc-provider --approve --cluster ${CLUSTER_NAME}  --region ${AWS_REGION} --profile zhy

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy_cn.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy_cn.json \
    --profile zhy


eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME}  \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole_${CLUSTER_NAME} \
  --attach-policy-arn=arn:aws-cn:iam::700951776385:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --profile zhy \
   --override-existing-serviceaccounts \

kubectl apply -f rbac-role.yaml --cluster=eks-workshop02.cn-northwest-1.eksctl.io


helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set region=${AWS_REGION} \
  --set vpcId=vpc-007a957cbd15fead9 \
  --set serviceAccount.name=aws-load-balancer-controller

echo "parameters:
  type: gp3" >> specs/storageclass.yaml


kubectl get deployment -n kube-system aws-load-balancer-controller --cluster=eks-workshop02.cn-northwest-1.eksctl.io

