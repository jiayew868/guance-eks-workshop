import random
from faker import Faker
import datetime
import mysql.connector

fake = Faker()

# 连接到MySQL数据库
connection = mysql.connector.connect(
    host="localhost",
    user="admin",
    password="123456",
    database="guancedb"  # 替换为您的数据库名称
)

cursor = connection.cursor()

# 清理数据
clear_user_table_query = "DELETE FROM T_User"
cursor.execute(clear_user_table_query)
clear_order_table_query = "DELETE FROM T_Order"
cursor.execute(clear_order_table_query)
connection.commit()


# 生成10个用户并插入到数据库
for _ in range(10):
    username = fake.user_name()
    email = fake.email()
    create_time = fake.date_time_this_decade()
    update_time = fake.date_time_this_decade()

    # 插入用户数据
    insert_user_query = "INSERT INTO T_User (username, email, create_time, update_time) VALUES (%s, %s, %s, %s)"
    cursor.execute(insert_user_query, (username, email, create_time, update_time))
    connection.commit()

# 生成1000条订单并插入到数据库
for _ in range(1000):
    user_id = random.randint(1, 10)  # 随机选择用户ID
    status = random.choice(["待支付", "已支付", "待发货", "已发货", "已完成"])
    order_date = fake.date_time_between(start_date="-1y", end_date="now")
    product_name = fake.word()
    product_price = round(random.uniform(1, 1000), 2)
    product_quantity = random.randint(1, 10)
    create_time = fake.date_time_this_decade()
    update_time = fake.date_time_this_decade()

    # 插入订单数据
    insert_order_query = "INSERT INTO T_Order (user_id, status, order_date, product_name, product_price, product_quantity, create_time, update_time) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"
    cursor.execute(insert_order_query, (
    user_id, status, order_date, product_name, product_price, product_quantity, create_time, update_time))
    connection.commit()

# 关闭数据库连接
cursor.close()
connection.close()
