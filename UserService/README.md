

### 镜像打包
docker build --build-arg JAR_FILE=UserService-1.0.jar -t awsdemo/user_service .

### run image
docker run \
--name user_service \
-p 8081:8081 \
-e JAVA_OPTS="-Dspring.cloud.nacos.config.server-addr=192.168.5.20:8848 -Dspring.cloud.nacos.discovery.server-addr=192.168.5.20:8848" \
-e envir="test" \
-e MY_NODE_NAME="user" \
-e MY_POD_NAMESPACE="ns" \
-e MY_POD_NAME="user_pod" \
-d \
awsdemo/user_service:latest


### 提交到ECR
    1, 创建repo
    2, login ecr aws ecr get-login-password --region cn-northwest-1 --profile zhy | docker login --username AWS --password-stdin 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn
    3，docker tag awsdemo/user_service:latest 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/user_service:latest
    4，docker push 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/user_service:latest

### 测试
