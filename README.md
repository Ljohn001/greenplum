# 安装前注意事项
## 1.本项目基于ansible部署安装基础环境
## 2.修改install/hosts 和 roles/greenplum/files/hosts 对应信息
## 3.百度云盘提供下载 Greenplum软件包 [https://pan.baidu.com/s/1Q_ekk2bSZVoRKA_8jkJJkA](https://pan.baidu.com/s/1Q_ekk2bSZVoRKA_8jkJJkA)

# 部署环境说明
### 共使用5台主机进行部署安装，内存为 16Gb
|ip地址|主机名|
|-:-|-:-|-:-|
|192.168.61.61 | mdw|
|192.168.61.62 | smdw|
|192.168.61.63 | sdw1|
|192.168.61.64 | sdw2|
|192.168.61.65 | sdw3|

# 系统版本及内核版本
```
[root@node61 ~]# cat /etc/centos-release
CentOS Linux release 7.4.1708 (Core) 
[root@node61 ~]# uname -r
3.10.0-693.21.1.el7.x86_64
```

#  1. GreenPlum 5.8.0 集群部署安装
## 1.1 ansible初始化后，导入变量

#  1. GreenPlum 5.8.0 集群部署安装
## 1.1 ansible初始化后，导入变量
```
cat >> .bashrc << EOF
export MASTER_DATA_DIRECTORY=/data/gpmaster/gpseg-1
EOF
source .bashrc
source /usr/local/greenplum-db/greenplum_path.sh
```

## 1.2 添加互信,root密码
```
rm -rf ~/.ssh/*
gpssh-exkeys -f  /home/gpadmin/all_nodes
```

## 1.3 检查主机
```
gpssh -f /home/gpadmin/all_nodes -e "ls -l"
```

## 1.4 安装gpdb到所有节点
```
gpseginstall -f /home/gpadmin/all_nodes -u gpadmin -p gpadmin
```

##  1.5 初始化sdw主节点,部署smdw备份节点
**
-c：指定初始化文件。
-h：指定segment主机文件。
-s：指定standby主机，创建standby节点。
**
```
su - gpadmin
cat >> .bashrc << EOF
export MASTER_DATA_DIRECTORY=/data/gpmaster/gpseg-1
source /usr/local/greenplum-db/greenplum_path.sh
EOF
source .bashrc
gpinitsystem -c /home/gpadmin/gpinitsystem_config -s smdw
y
yes
```

>> 安装失败回退脚本
```
cd ~/gpAdminLogs/
backout_gpinitsystem_gpadmin_20180508_120753
```
**
可以使用此脚本清理部分创建的Greenplum数据库系统。此回退脚本将删除任何实用程序创建的数据目录，postgres进程和日志文件。纠正导致gpinitsystem失败并运行退出脚本的错误后，您应该准备重试初始化您的Greenplum数据库数组。
**

## 1.6 添加访问权限
```
echo "host     all         gpadmin         0.0.0.0/0       md5" >> /data/gpmaster/gpseg-1/pg_hba.conf
```

## 1.7 同步pg_hba.conf到smdw备份节点，重新加载gpdb配置文件
```
gpscp -h smdw -v $MASTER_DATA_DIRECTORY/pg_hba.conf =:$MASTER_DATA_DIRECTORY/
gpstop -u
```

## 1.8 测试GPDB集群状态
```
gpstate -s
```

## 1.9 设置gpadmin远程访问密码
```
psql postgres gpadmin
alter user gpadmin encrypted password 'gpadmin';
```

## 1.10 查询测试
```
psql -h 192.168.61.61 -p 5432 -d postgres -U gpadmin -c 'select dfhostname, dfspace,dfdevice from gp_toolkit.gp_disk_free order by dfhostname;'
psql -h 192.168.61.61 -p 5432 -d postgres -U gpadmin -c '\l+'
```

``` ### 至此 GreenPlum 集群部署完成 ### ```

# 2. GreenPlum-cc-web 4.0 部署安装
## 2.1 gpadmin创建gpperfmon数据库, 默认用户gpmon
```
su - gpadmin
source /usr/local/greenplum-db/greenplum_path.sh
gpperfmon_install --enable --password gpmon --port 5432
```
```正常显示 -gpperfmon will be enabled after a full restart of GPDB ```

## 2.2 重启gpdb，没有error为正常
```
echo "host     all         gpmon         0.0.0.0/0    md5" >> $MASTER_DATA_DIRECTORY/pg_hba.conf
gpstop -afr
```

## 2.3 拷贝mdw主配置文件到smdw备份配置文件
```
gpscp -h smdw -v $MASTER_DATA_DIRECTORY/pg_hba.conf =:$MASTER_DATA_DIRECTORY/
gpscp -h smdw -v ~/.pgpass =:~/
```
## 2.4 设置gpmon密码为空，安装gcc需要
```
psql -d gpperfmon -c "alter user gpmon encrypted password '';"
```

## 2.5 安装greenplum-cc-web
> root用户执行

```
/home/gpadmin/gpccinstall-4.0.0
q
Do you agree to the Pivotal Greenplum Command Center End User License Agreement? Yy/Nn (Default=Y)
Where would you like to install Greenplum Command Center? (Default=/usr/local)

What would you like to name this installation of Greenplum Command Center? (Default=gpcc)

What port would you like gpcc webserver to use? (Default=28080)

Would you like to enable kerberos? Yy/Nn (Default=N)

Would you like enable SSL? Yy/Nn (Default=N)

Installation in progress...
```

## 2.6 改变属性
```
chown -R gpadmin.gpadmin /usr/local/greenplum-cc-web-4.0.0
```

## 2.7 安装web页面
```
su - gpadmin
cat >> .bashrc << EOF
source /usr/local/greenplum-cc-web-4.0.0/gpcc_path.sh
EOF
source .bashrc
gpscp -h smdw -v ~/.bashrc =:~/.bashrc
```

## 2.8 修改gpmon密码
```
psql -d gpperfmon -c "alter user gpmon encrypted password 'gpmon';"
```

## 2.9 启动gpcc web服务
```
gpcc start
gpstop -afr
```

## 2.10 查询生成数据
```
psql -d gpperfmon -c 'show timezone'
psql -d gpperfmon -c 'select * from system_now'
```

## 2.11 访问web页面
=====================================================
	 http://192.168.61.61:28080
=====================================================
``` ### 至此web监控页面完成 ###```

# 3. 验证集群
## 3.1 验证网络性能
```
gpcheckperf -f gp_all_nodes -r N -d /tmp/
```

### 3.2 验证磁盘I/O和内存带宽性能
```
gpcheckperf -f gp_all_nodes -r ds -d /tmp
```

### 3.3 验证内存带宽性能
```
gpcheckperf -f gp_all_nodes -r s -d /tmp
```

# 4. postgres 常用命令

## 4.1 数据库启动与关闭
```
### 直接启动，不交互
gpstart -a

### 直接停止，不交互
gpstop -a

### 重新加载配置文件
gpstop -u

### 重新加载配置重启
gpstop -afr
```

### 4.2 设置默认数据库
```
export PGDATABASE=testdb;
```

### 4.3 默认登录testdb
```
psql
psql (8.3.23)
Type "help" for help.

testdb=#
```

### 4.4 终端登录系统
```
psql -d postgres
```

## 4.5 设置gpadmin密码
```
psql postgres gpadmin
alter user gpadmin encrypted password 'gpadmin';
```

## 4.6 用户登陆
```
psql -h 192.168.61.61 -p 5432 -d postgres -U gpadmin -W
psql -h 192.168.61.61 -p 5432 -d gpperfmon -U gpmon
```

## 4.7 列出当前连接
```
postgres=# \connect
You are now connected to database "postgres" as user "gpadmin".

postgres=# \conninfo
You are connected to database "postgres" as user "gpadmin" via socket in "/tmp" at port "5432".
```

## 4.8 列出所有数据库
```
\l
```

## 4.9 切换数据库
```
\c template1
```

## 4.10 查看数据库
```
select dfhostname, dfspace,dfdevice from gp_toolkit.gp_disk_free order by dfhostname;
\l+
```

## 4.11 查看表内容
```
\d
```

## 4.12 创建数据库
```
create database testdb;
```

## 4.13 退出数据库
```
\q
```

## 4.14 启用执行语句时间显示
```
\timing on
```

# 5. 查询数据库并创建表
```
testdb=# select version();
version
-----------------------------------------------------------------------
 PostgreSQL 8.3.23 (Greenplum Database 5.7.0 build commit:f7c6eb5cc61b25a7ff9c5a657d6f903befbae013) on x86_64-pc-linux-gnu, compiled by
 GCC gcc (GCC) 6.2.0, 64-bit compiled on Mar 30 2018 14:20:38
(1 row)
===============================
testdb=# create table test01(id int primary key,name varchar(128));
```

## 5.1 查询数据库
```
select * from test01;
```

## 5.2 查看当前用户名
```
select *from current_user;
select user;
```

## 5.3授权用户
```
alter role 

admin with password 'gpadmin';
```

## 5.4 访问权限设置 pg_hba.conf
```
host testdb gpadmin 10.12.7.16/32 md5
```

## 5.5 设置用户密码
```
create user xiao with password 'king1111';
```

# 6. 基本语法
## 6.1 获取语法介绍
```
\h create view
```

## 6.2 创建表
### 6.2.1 未设置主键
```
testdb=# create table test001(id int, name varchar(128));
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause -- Using column named 'id' as the Greenplum Database data distribution key for this table.
HINT:  The 'DISTRIBUTED BY' clause determines the distribution of data. Make sure column(s) chosen are the optimal data distribution key to minimize skew.
```

### 6.2.2 设置一个主键
```
testdb=# create table test002(id int, name varchar(128)) distributed by(id);
```

#### 6.2.3 设置两个主键
```
testdb=# create table test003(id int, name varchar(128)) distributed by(id,name);
```

#### 6.2.4 建表随机分布
```
testdb=# create table test004(id int, name varchar(128)) distributed randomly;
```

#### 6.2.5 唯一键分布
```
testdb=# create table test005(id int primary key, name varchar(128));
NOTICE:  CREATE TABLE / PRIMARY KEY will create implicit index "test005_pkey" for table "test005"

testdb=# create table test006(id int unique, name varchar(128));
NOTICE:  CREATE TABLE / UNIQUE will create implicit index "test006_id_key" for table "test006"
```

#### 6.2.6 指定分布键与主键不一样，分部件会被更改为主键
```
testdb=# create table test007(id int unique, name varchar(128)) distributed by(id,name);
NOTICE:  updating distribution policy to match new unique index
NOTICE:  CREATE TABLE / UNIQUE will create implicit index "test007_id_key" for table "test007"

testdb=# \d test007;
           Table "public.test007"
 Column |          Type          | Modifiers 
--------+------------------------+-----------
 id     | integer                | 
 name   | character varying(128) | 
Indexes:
    "test007_id_key" UNIQUE, btree (id)
Distributed by: (id)
```

#### 6.2.7 拷贝结构相同数据表
```
testdb=# create table test001_like (like test001);
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause, defaulting to distribution columns from LIKE table
CREATE TABLE
testdb=# \d test001_like;
         Table "public.test001_like"
 Column |          Type          | Modifiers 
--------+------------------------+-----------
 id     | integer                | 
 name   | character varying(128) | 
Distributed by: (id)

testdb=# \d test001;
           Table "public.test001"
 Column |          Type          | Modifiers 
--------+------------------------+-----------
 id     | integer                | 
 name   | character varying(128) | 
Distributed by: (id)
```

## 6.3 插入键值 insert
### 6.3.1
```
testdb=# insert into test001 values(100,'jack'),(101,'david'),(102,'tom'),(103,'lily');
INSERT 0 4
```

## 6.4 查询语句 select
### 6.4.1 示例
```
# 查询表内容
testdb=# select id,name from test001 order by id;
 id | name
----+------
(0 rows)

# 不加入order by，数据顺序将随机显示
testdb=# select * from test001;
 id  | name
-----+-------
 102 | tom
 103 | lily
 101 | david
 100 | jack
(4 rows)

testdb=# select * from test001;
 id  | name 
-----+-------
 100 | jack
 103 | lily
 102 | tom
 101 | david
(4 rows)

# 不指定from子句，执行函数
testdb=# select greatest(1,2);
 greatest
----------
        2
(1 row)

# 简单科学计算
testdb=# select 2^3+3+9*(8+1);
 ?column?
----------
       92
(1 row)

```

### 6.4.2 复制查询到表结构及数据
```
testdb=# create table test02 as select * from test001;
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause. Creating a NULL policy entry.
SELECT 4

# 手动指定 distributed 关键字
testdb=# create table test3 as select * from test001 distributed by(id);
SELECT 4
```
