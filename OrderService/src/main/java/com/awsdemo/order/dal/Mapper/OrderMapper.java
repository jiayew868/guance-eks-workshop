package com.awsdemo.order.dal.Mapper;

import com.awsdemo.core.entity.Order;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Select;
import org.springframework.stereotype.Repository;

import java.util.List;


@Repository
public interface OrderMapper extends BaseMapper<Order> {

       @Select("select * from T_Order where user_id = #{userId}")
       List<Order> findAllByUserId(Long userId);

}
