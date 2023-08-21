package org.awsdemo.user.controller;


import com.alibaba.nacos.api.config.annotation.NacosValue;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.awsdemo.core.entity.Order;
import org.awsdemo.core.entity.User;
import org.awsdemo.user.entity.UserOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/user")
public class UserController {

    private static final Logger logger = LogManager.getLogger(UserController.class);

    @Autowired
    private RestTemplate restTemplate;

    @NacosValue(value = "${useLocalCache:false}", autoRefreshed = true)
    private boolean useLocalCache;

    @GetMapping("/hello")
    public String hello () {
        String value = String.format("%s,%s" , "user","1111");
        return value;
    }

    @GetMapping(value = "/test")
    @ResponseBody
    public boolean get() {
        return useLocalCache;
    }

    @GetMapping(value = "/{userid}/user_orders")
    public UserOrder userOrder(@PathVariable("userid") String userId){

        User user = new User();
        user.setUserId(userId);

        ResponseEntity<Order[]> responseEntity = restTemplate.getForEntity("http://order-service/order/list/userid/"+ userId, Order[].class);
        Order[] orderArray = responseEntity.getBody();
        List<Order> orders = new ArrayList<>();
        if (orderArray != null) {
            orders = Arrays.stream(orderArray).collect(Collectors.toList());
        }

       UserOrder userOrder = new UserOrder(user,orders);
       return userOrder;
    }


}
