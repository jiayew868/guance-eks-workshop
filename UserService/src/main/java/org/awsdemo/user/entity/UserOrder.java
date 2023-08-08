package org.awsdemo.entity;


import com.google.common.collect.Lists;
import org.awsdemo.core.entity.Order;
import org.awsdemo.core.entity.User;

import java.util.List;

public class UserOrder {

    private User user = new User();

    private List<Order> orders = Lists.newArrayList();

    public UserOrder(User user, List<Order> orders) {
        this.user = user;
        this.orders = orders;
    }


    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public List<Order> getOrders() {
        return orders;
    }

    public void setOrders(List<Order> orders) {
        this.orders = orders;
    }
}
