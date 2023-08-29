docker remove awsdemo/user_service

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

