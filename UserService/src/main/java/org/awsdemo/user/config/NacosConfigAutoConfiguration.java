package org.awsdemo.config;


import com.alibaba.nacos.spring.context.annotation.config.NacosPropertySource;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;

@Configuration
@NacosPropertySource(dataId = "user-svr", autoRefreshed = true)
public class NacosConfigAutoConfiguration {
}
