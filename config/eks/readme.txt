



eksctl create cluster -f cluster.yaml


eksctl upgrade cluster --config-file cluster.yaml


 kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller












