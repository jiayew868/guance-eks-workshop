package org.awsdemo.order.controller;

import cn.hutool.core.collection.CollectionUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.awsdemo.core.entity.Order;
import org.awsdemo.order.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;


@RestController
@RequestMapping("/order")
@RefreshScope
public class OrderController {

    private static final Logger logger = LogManager.getLogger(OrderController.class);

    @Value(value = "${useLocalCache:false}")
    private boolean useLocalCache;

    @Value(value = "${appVersion:v1}")
    private String appVersion;

    @Autowired
    private OrderService orderService;


    @GetMapping("/version")
    public String hello() {
        String value = String.format("version %s", this.appVersion);

        logger.debug("debug This is a debug message.");
        logger.info("info This is an info message.");
        logger.error("error This is an error message.");

        return value;
    }

    @GetMapping("/list/userid/{userid}")
    public List<Order> orders(@PathVariable("userid") Long userId) {

        List<Order> values = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            Order order = new Order();
            order.setId(Long.parseLong("00" + i));
            values.add(order);
        }

        CollectionUtil.addAll(values,orderService.getOrdersByUserId(userId));

        return values;
    }

    @GetMapping("/list/{orderId}")
    public Order getOrder(@PathVariable("orderId") Long orderId){
        return orderService.getOrderById(orderId);
    }


    @GetMapping("/list")
    public List<Order> getAllOrders(){
        return orderService.getOrders();
    }

    @GetMapping("/{orderId}")
    public Order getOrderById(@PathVariable("orderId") Long orderId){

        return orderService.getOrderById(orderId);
    }

}
