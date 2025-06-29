# guance-eks-workshop






aws eks update-kubeconfig --region cn-northwest-1 --name eks-workshop02


### docker
docker run -itd --name redis-test -p 6379:6379 redis
docker run -itd --name mysql-test -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 mysql

测试
http://k8s-nacosdem-nacosdem-7f547f817f-437491094.ap-southeast-1.elb.amazonaws.com/user/all
http://k8s-nacosdem-nacosdem-7f547f817f-437491094.ap-southeast-1.elb.amazonaws.com/user/3/user-orders