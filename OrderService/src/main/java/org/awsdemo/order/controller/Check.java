package org.awsdemo.order.controller;

import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/check")
@RefreshScope
public class Check {

    @RequestMapping("/health")
    private String health(){
        return "I am OK";
    }





}
