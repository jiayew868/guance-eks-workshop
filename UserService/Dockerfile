# 基于哪个镜像
FROM anapsix/alpine-java:latest

# 设置工作目录
WORKDIR /app

# 声明需要挂载的目录
VOLUME /tmp
VOLUME /app/logs

# 设置环境变量
ENV LOG_PATH=""
ENV envir=""
ENV JAVA_OPTS=""
ENV DD_AGENT=""

# 设置构建参数
ARG JAR_FILE

COPY ["../libs/dd-java-agent-1.19.1.jar","/usr/dd-java-agent/agent/"]

# 复制jar文件到容器中
COPY /UserService/target/${JAR_FILE} app.jar

# 声明需要暴露的端口
EXPOSE 8082
# 设置容器启动命令

ENTRYPOINT ["sh","-c","java -Djava.security.egd=file:/dev/./urandom $DD_AGENT $JAVA_OPTS -Ddd.service=user-service -jar app.jar --logging.file.path=$LOG_PATH ${PARAMS} --spring.profiles.active=$envir ${PARAMS}  2>&1 > /dev/null"]
