package org.awsdemo.order.controller;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.awsdemo.core.entity.Order;
import org.springframework.beans.factory.annotation.Value;
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
public class OrderService {

    private static final Logger logger = LogManager.getLogger(OrderService.class);

    @Value(value = "${useLocalCache:false}")
    private boolean useLocalCache;

    @Value(value = "${version:v1}")
    private String appVersion;


    @GetMapping("/version")
    public String hello() {
        String value = String.format("version %s", this.appVersion);

        logger.debug("debug This is a debug message.");
        logger.info("info This is an info message.");
        logger.error("error This is an error message.");

        return value;
    }

    @GetMapping("/list/userid/{userid}")
    public List<Order> orders(@PathVariable("userid") String userId) {

        List<Order> values = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            Order order = new Order();
            order.setOrderId("00" + i);
            values.add(order);
        }
        return values;
    }
}
