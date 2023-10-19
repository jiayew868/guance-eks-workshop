
***

## 前提条件
[安装 DataKit Operator 和 DataKit](https://github.com/GuanceDemo/guance-datakit-demo)

***

## 方式一：Helm 方式手动安装
> 通过 Helm 安装至 Kubernetes 集群，适合快速安装 guance-java-ruoyi-demo 进行演示的场景。

### 1. 安装
#### 1.1 执行安装
```shell
cd /ruoyi
helm upgrade -i ruoyi -n ruoyi --create-namespace ./deployment/helm
```
#### 1.2 terraform 创建观测云资源
[Terraform安装](https://www.terraform.io/downloads.html)

环境变量：
- `GUANCE_ACCESS_TOKEN`: 观测云 Key ID，创建方式：[API Key](https://docs.guance.com/management/api-key/)
- `GUANCE_REGION`: 观测云 region，可选项：

```shell
cd guance-java-ruoyi-demo/terraform
export GUANCE_ACCESS_TOKEN=xxx
export GUANCE_REGION=xxx
terraform init
terraform plan
terraform apply -auto-approve 
```

#### 1.3 访问方式
部署完成后可通过 web-service 的 NodePort 方式进行访问，默认端口为 30001
```shell
kubectl get pod -n ruoyi -o wide
```
```shell
kubectl apply -f rouyi-Ingress-alb.yaml
```

### ingress 地址
```shell
kubectl get ingress -n ruoyi
```

### 在观测云的控制台，定义个`ruoyi_web` 的APP


### 2. 卸载
#### 2.1 删除观测云资源
```shell
cd ruoyi/terraform
terraform destroy -auto-approve 
```
#### 2.2 卸载若依
```
helm uninstall ruoyi -n ruoyi
```



