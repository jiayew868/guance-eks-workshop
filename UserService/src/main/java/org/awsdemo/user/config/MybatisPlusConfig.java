package org.awsdemo.user.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("org.awsdemo.user.ar.mapper")
public class MybatisPlusConfig {
}
