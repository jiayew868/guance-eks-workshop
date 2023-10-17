

### 镜像打包
docker build --build-arg JAR_FILE=UserService-1.0.jar -t awsdemo/user_service -f Dockerfile ../


### run image
docker run \
--name user_service \
-p 8081:8081 \
-e JAVA_OPTS=" -Ddd.agent.port=9529 -Dspring.cloud.nacos.config.server-addr=192.168.5.102:8848 -Dspring.cloud.nacos.discovery.server-addr=192.168.5.102:8848" \
-e envir="test" \
-e LOG_PATH="/var/log/awsdemo/user-svr" \
-e MY_NODE_NAME="user" \
-e MY_POD_NAMESPACE="ns" \
-e MY_POD_NAME="user_pod" \
-d \
awsdemo/user_service:latest


### 提交到ECR
    1, 创建repo
       
    2, aws ecr get-login-password --region cn-northwest-1 --profile zhy | docker login --username AWS --password-stdin 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn
    3，docker tag awsdemo/user_service:latest 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/user_service:latest
    4，docker push 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/user_service:latest


### 提交共有ECR
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/q1p2c6o9
docker tag awsdemo/user_service:latest public.ecr.aws/q1p2c6o9/awsdemo/user_service:latest
docker push public.ecr.aws/q1p2c6o9/awsdemo/user_service:latest


### Test API
http://localhost:8081/user/all
http://localhost:8081/user/1/user-orders
