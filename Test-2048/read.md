
eksctl create fargateprofile \
--cluster my-cluster \
--region region-code \
--name alb-sample-app \
--namespace game-2048

kubectl apply -f 2048_full.yaml

kubectl get ingress/ingress-2048 -n game-2048