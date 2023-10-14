package com.awsdemo.order.service;

import com.awsdemo.core.entity.Order;
import com.awsdemo.order.tool.RedisUtil;
import lombok.extern.java.Log;
import com.awsdemo.order.dal.Mapper.OrderMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;

@Log
@Service
public class OrderService {

    private RedisUtil redisUtil;

    private  OrderMapper orderMapper;

    @Autowired
    public OrderService(RedisUtil redisUtil, OrderMapper orderMapper) {
        this.redisUtil = redisUtil;
        this.orderMapper = orderMapper;
    }

    @Cacheable(cacheNames = "redisCache",key = "#root.methodName +'[' + #id + ']'")
    public Order getOrderById(Long id){
        return orderMapper.selectById(id);
    }

    public List<Order> getOrders(){
        return orderMapper.selectList(null);
    }

    public List<Order> getOrdersByUserId(Long userId){
        return orderMapper.findAllByUserId(userId);
    }


}
