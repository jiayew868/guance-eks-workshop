package org.awsdemo.core.entity;


import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import java.io.Serializable;
import java.time.LocalDateTime;


@Data
@ToString
@EqualsAndHashCode
@TableName(value = "T_Order")
public class Order implements Serializable {

    @TableId(value = "order_id",type = IdType.AUTO)
    private Long id;

    @TableField("user_id")
    private Long userId;

    @TableField("status")
    private String status;

    @TableField("order_date")
    private LocalDateTime orderDate;

    @TableField("product_name")
    private String productName;

    @TableField("product_price")
    private double productPrice;

    @TableField("product_quantity")
    private int quantity;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.UPDATE)
    private LocalDateTime updateTime;

}
