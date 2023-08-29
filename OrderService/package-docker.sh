docker remove awsdemo/order_service

docker remove tag 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/order_service:latest

docker build --build-arg JAR_FILE=OrderService-1.0.jar -t awsdemo/order_service .


docker tag awsdemo/order_service:latest 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/order_service:latest

docker push 700951776385.dkr.ecr.cn-northwest-1.amazonaws.com.cn/awsdemo/order_service:latest


