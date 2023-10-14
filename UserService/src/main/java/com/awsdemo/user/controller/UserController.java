package com.awsdemo.user.controller;

import com.awsdemo.core.entity.Order;
import com.awsdemo.core.entity.User;
import com.awsdemo.user.entity.UserOrder;
import com.alibaba.nacos.api.config.annotation.NacosValue;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import org.assertj.core.util.Lists;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.loadbalancer.LoadBalancerClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/user")
public class UserController {

    private static final Logger logger = LogManager.getLogger(UserController.class);


    @Autowired
    private LoadBalancerClient loadBalancerClient;

    @Resource
    RestTemplate restTemplate;

    @NacosValue(value = "${useLocalCache:false}", autoRefreshed = true)
    private boolean useLocalCache;

    @GetMapping("/hello")
    public String hello () {
        String value = String.format("%s,%s" , "user","1111");
        logger.info(value);
        return value;
    }

    @GetMapping(value = "/test")
    @ResponseBody
    public boolean get() {
        return useLocalCache;
    }

    @GetMapping(value = "/{userid}/user-orders")
    public UserOrder userOrder(@PathVariable("userid") Long userId){
        logger.info("userOrder -- start");
        User user = new User();
        user.setId(userId);

        ServiceInstance serviceInstance = loadBalancerClient.choose("order-service");

        logger.info("order service ip : {} port : {}",serviceInstance.getHost(),serviceInstance.getPort());

        ResponseEntity<Order[]> responseEntity = restTemplate.getForEntity("http://order-service/order/list/userid/"+ userId, Order[].class);
        Order[] orderArray = responseEntity.getBody();
        List<Order> orders = new ArrayList<>();
        if (orderArray != null) {
            orders = Arrays.stream(orderArray).collect(Collectors.toList());
        }

       UserOrder userOrder = new UserOrder(user,orders);
        logger.info("userOrder -- end");
       return userOrder;
    }

    @GetMapping(value = "/all")
    public List<User> getALL(){
        User user = new User();
        return Lists.newArrayList();
        //return user.selectAll();
    }


}
