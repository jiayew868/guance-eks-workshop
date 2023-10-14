

### 编译jar package
mvn clean install -Dskip.test=ture

### 镜像打包
docker build --build-arg JAR_FILE=OrderService-1.0.jar -t awsdemo/order_service .

docker run \
    --name order_service \
    -p 8082:8082 \
    -e JAVA_OPTS="-Dspring.cloud.nacos.config.server-addr=192.168.5.102:8848 -Dspring.cloud.nacos.discovery.server-addr=192.168.5.102:8848" \
    -e envir="test" \
    -e LOG_PATH="/var/log/awsdemo/order-svr" \
    -e MY_NODE_NAME="order" \
    -e MY_POD_NAMESPACE="ns" \
    -e MY_POD_NAME="order_pod" \
    -d \
    awsdemo/order_service:latest

### 提交到ECR
    1, 创建repo
            https://cn-northwest-1.console.amazonaws.cn/ecr/repositories?region=cn-northwest-1
    2, login ecr 
            aws ecr get-login-password --region cn-northwest-1 --profile zhy | docker login --username AWS --password-stdin 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn
    3，tag  
            docker tag awsdemo/order_service:latest 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/order_service:latest
    4，docker push 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/order_service:latest
    
### 部署Pod到EKS
kubectl apply -f ./eks/order-service-deployment.yaml

### push public REPO
    
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/q1p2c6o9
    docker tag awsdemo/order_service:latest public.ecr.aws/q1p2c6o9/awsdemo/order_service:latest
    docker push public.ecr.aws/q1p2c6o9/awsdemo/order_service:latest

### Test API
http://localhost:8082/order/{orderid}
http://localhost:8082/order/list
http://localhost:8082/order/list/userid/{userid}


    

