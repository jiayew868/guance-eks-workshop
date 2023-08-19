# 基于哪个镜像
FROM anapsix/alpine-java:latest

# 设置工作目录
WORKDIR /app

# 声明需要挂载的目录
VOLUME /tmp
VOLUME /app/logs

# 设置环境变量
ENV envir=""
ENV JAVA_OPTS=""
ENV LOG_PATH=""

# 设置构建参数
ARG JAR_FILE

# 复制jar文件到容器中
COPY target/${JAR_FILE} app.jar

# 声明需要暴露的端口
EXPOSE 8082
# 设置容器启动命令

ENTRYPOINT ["sh","-c","java -Djava.security.egd=file:/dev/./urandom $JAVA_OPTS -jar app.jar --spring.profiles.active=$envir --logging.file.path=$LOG_PATH"]
