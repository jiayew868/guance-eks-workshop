create database  guancedb;

use guancedb;

DROP TABLE IF EXISTS `User`;
DROP TABLE IF EXISTS `Order`;


CREATE TABLE T_User (
                        user_id INT AUTO_INCREMENT ,
                        username VARCHAR(255) NOT NULL,
                        email VARCHAR(255) NOT NULL,
                        `create_time` datetime DEFAULT NULL,
                        `update_time` datetime DEFAULT NULL,
                        PRIMARY KEY (`user_id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

# -----

CREATE TABLE T_Order (
                         order_id INT AUTO_INCREMENT,
                         `user_id` INT NOT NULL,
                         status VARCHAR(50) NOT NULL,
                         order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         product_name VARCHAR(255) NOT NULL,
                         product_price DECIMAL(10, 2) NOT NULL,
                         product_quantity INT NOT NULL,
                         `create_time` datetime DEFAULT NULL,
                         `update_time` datetime DEFAULT NULL,
                         PRIMARY KEY (`order_id`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
