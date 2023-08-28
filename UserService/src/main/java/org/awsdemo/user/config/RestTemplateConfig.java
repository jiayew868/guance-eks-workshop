package org.awsdemo.user.config;

import org.springframework.beans.factory.annotation.Configurable;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.cloud.loadbalancer.annotation.LoadBalancerClient;
import org.springframework.cloud.loadbalancer.annotation.LoadBalancerClients;
import org.springframework.cloud.loadbalancer.core.ReactorLoadBalancer;
import org.springframework.cloud.loadbalancer.core.ServiceInstanceListSupplier;
import org.springframework.cloud.loadbalancer.support.LoadBalancerClientFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;
import org.springframework.web.client.RestTemplate;

@Configurable
@LoadBalancerClients(value = {
        @LoadBalancerClient(name = "order-service",configuration = MyLoadBalancerConfig.class),
        @LoadBalancerClient(name = "user-service",configuration = MyLoadBalancerConfig.class)
})
public class RestTemplateConfig {


    @Bean
    @LoadBalanced // 开启负载均衡 Ribbon, 发送的请求都会被Ribbon拦截。必须使用应用名代替ip，否则报错
    public RestTemplate restTemplate(){
        return new RestTemplate();
    }

//
//    @Bean
//    ReactorLoadBalancer<ServiceInstance> randomLoadBalancer(Environment environment,
//                                                            LoadBalancerClientFactory loadBalancerClientFactory) {
//        String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
//
//        return new NacosSameClusterWeightedRule(loadBalancerClientFactory
//                .getLazyProvider(name, ServiceInstanceListSupplier.class),
//                name);
//    }

}
