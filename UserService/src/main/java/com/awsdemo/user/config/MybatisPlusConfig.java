package com.awsdemo.user.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("com.awsdemo.user.ar.mapper")
public class MybatisPlusConfig {

}
