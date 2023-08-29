package org.awsdemo.order.controller;

import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.boot.actuate.endpoint.annotation.WriteOperation;
import org.springframework.stereotype.Component;

@Component
@Endpoint(id = "demo")
public class DemoEndpoint {

    @ReadOperation
    public String get() {
        return "Hello, this is a demo endpoint!";
    }

    @WriteOperation
    public String set() {
        return "Demo endpoint has been updated!";
    }
}
