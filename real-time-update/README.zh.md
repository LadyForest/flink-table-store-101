# 实时更新
*其它语言版本* [English](https://github.com/LadyForest/flink-table-store-101/tree/master/real-time-update)

## 用例简介
Flink Table Store（以下简称 **FTS**）在千万级数据规模的实时更新场景展示

- 关于数据生成  
[TPC-H](https://www.tpc.org/tpch/) 作为一个经典的 Ad-hoc query 性能测试 Benchmark，其自身所包含的数据 relation 和 22 个 query 已经涵盖了丰富的商业场景（统计指标与大部分电商需求十分类似）。本用例选取了针对订单明细表 `lineitem` 查询的 Q1 和 Q6，包含 2 个常见 BI 需求，展示在千万级别数据量时 FTS 的实时更新能力，整体流程如下图所示
![diagram](./pictures/diagram.png)
`lineitem` 的 schema 如下表所示，每行记录在 128 bytes 左右
  <table>
      <thead>
          <tr>
              <th>字段</th>
              <th>类型</th>
              <th>描述</th>
          </tr>
      </thead>
      <tbody>
          <tr>
            <td>l_orderkey</td>
            <td>INT NOT NULL</td>
            <td>主订单 key（即主订单 ID）联合主键第一位</td>
          </tr>
          <tr>
            <td>l_partkey</td>
            <td>INT NOT NULL</td>
            <td>配件 key（即商品 ID）</td>
          </tr>
          <tr>
            <td>l_suppkey</td>
            <td>INT NOT NULL</td>
            <td>供应商 key（即卖家 ID）</td>
          </tr>
          <tr>
            <td>l_linenumber</td>
            <td>INT NOT NULL</td>
            <td>子订单 key（即子订单 ID）联合主键第二位</td>
          </tr>
          <tr>
            <td>l_quantity</td>
            <td>DECIMAL(15, 2) NOT NULL</td>
            <td>商品数量</td>
          </tr>
          <tr>
            <td>l_extendedprice</td>
            <td>DECIMAL(15, 2) NOT NULL</td>
            <td>商品价格</td>
          </tr>
          <tr>
            <td>l_discount</td>
            <td>DECIMAL(15, 2) NOT NULL</td>
            <td>商品折扣</td>
          </tr>
          <tr>
            <td>l_tax</td>
            <td>DECIMAL(15, 2) NOT NULL</td>
            <td>商品税</td>
          </tr>
          <tr>
            <td>l_returnflag</td>
            <td>CHAR(1) NOT NULL</td>
            <td>订单签收标志，<code>A</code> 代表 accepted 签收，<code>R</code> 代表 returned 拒收，<code>N</code> 代表 none 未知<td>
          </tr>
          <tr>
            <td>l_linestatus</td>
            <td>CHAR(1) NOT NULL</td>
            <td>子订单状态，发货日期晚于 1995-06-17 之前的订单标记为 <code>O</code>，否则标记为 <code>F</code></td>
          </tr>
          <tr>
            <td>l_shipdate</td>
            <td>DATE NOT NULL</td>
            <td>订单发货日期</td>
          </tr>
          <tr>
            <td>l_commitdate</td>
            <td>DATE NOT NULL</td>
            <td>订单提交日期</td>
          </tr>
          <tr>
            <td>l_receiptdate</td>
            <td>DATE NOT NULL</td>
            <td>收货日期</td>
          </tr>
          <tr>
            <td>l_shipinstruct</td>
            <td>CHAR(25) NOT NULL</td>
            <td>收货要求，比如 <code>DELIVER IN PERSON</code>本人签收，<code>TAKE BACK RETURN</code> 退货，<code>COLLECT COD</code> 货到付款</td>
          </tr>
          <tr>
            <td>l_shipmode</td>
            <td>CHAR(10) NOT NULL</td>
            <td>快递模式，有 <code>SHIP</code> 海运，<code>AIR</code> 空运，<code>TRUCK</code> 陆运，<code>MAIL</code> 邮递等类型</td>
          </tr>
          <tr>
            <td>l_comment</td>
            <td>VARCHAR(44) NOT NULL</td>
            <td>订单注释</td>
          </tr>
      </tbody>
  </table>

- 商业洞察需求  
  
  1. 对已发货的订单，根据订单状态和收货状态统计订单数、商品数、总营业额、总利润、平均出厂价、平均折扣价、平均折扣含税价等指标（对应 TPC-H Q1）
  2. 通过特定的销量和折扣过滤出一批商品，如果取消折扣，能在多大程度上降低成本，提升利润（对应 TPC-H Q6）

- 步骤简介 
  1. 通过 docker-compose 启动服务，以 scale factor 10 初始化 MySQL container, 产生约五千九百万条订单明细（约 7.4 G），并自动导入到名为 `tpch_s10` 数据库下面的 `lineitem` 表；紧接着会触发 TPC-H toolkit 产生 100 组 RF1（新增订单） 和 RF2（删除订单）
  2. 在本地下载 Flink、Flink CDC 及 FTS 相关依赖，修改配置，启动 SQL CLI
  3. 将 MySQL 订单明细表通过 Flink CDC 同步到 FTS 对应表，并启动 Q1 和 Q6 的实时写入任务


## 快速开始 

### 第一步：构建镜像，启动容器服务
在开始之前，请确保本机 Docker Disk Image 至少有 20G 空间，若空间不足，请将 docker-compose 文件中第 32 行 `sf` 改为 1（减少数据规模，此时生成约 700M 数据）
在 `flink-table-store-101/real-time-update` 目录下运行
```bash
docker-compose build --no-cache && docker-compose up -d --force-recreate
```
构建镜像阶段将会使用 TPC-H 自带工具产生约 7.4G 数据 (scale factor = 10)，整个构建过程大约需要 1-2 分钟左右，镜像构建完成后容器启动，将会自动创建名为 `tpch_s10` 的数据库，在其中创建 `lineitem` 表并自动导入数据。可以通过 `docker logs ${container-id}` 来查看导入进度，此过程耗时约 15-20 分钟
- 注1：container-id 可以通过 `docker ps` 命令获取
- 注2：还可以通过 `docker exec -it ${container-id} bash` 进入容器内部，当前工作目录即为 `/tpch/dbgen`, 用 `wc -l lineitem.tbl.*` 查看产生的数据行数；与导入 MySQL 的数据进行比对
- 注3：当看到如下日志时，说明全量数据已经导入完成 
    ```plaintext
    Finish loading data, current #(record) is 59986052, and will generate update records in 3 seconds
    ``` 

    当看到如下日志时，说明增量数据已导入完成
    ```plaintext
    [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.30'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.
    ```

### 第二步：下载 Flink、FTS 及其他所需依赖
Demo 运行使用 Flink 1.14.5 版本（ [flink-1.14.5 下载链接](https://flink.apache.org/downloads.html#apache-flink-1145) ），需要的其它依赖如下
- Flink MySQL CDC Connector 
- 基于 Flink 1.14 编译的 FTS
- Hadoop Bundle Jar

为方便操作，您可以直接在本项目的 `flink-table-store-101/flink/lib` 目录下载所有依赖，并放置于 `flink-1.14.5/lib` 目录下，也可以自行下载及编译

- [flink-sql-connector-mysql-cdc-2.3-SNAPSHOT.jar](https://repo1.maven.org/maven2/com/ververica/flink-sql-connector-mysql-cdc/2.3-SNAPSHOT/flink-sql-connector-mysql-cdc-2.3-SNAPSHOT.jar) 
- [Hadoop Bundle Jar](https://repo.maven.apache.org/maven2/org/apache/flink/flink-shaded-hadoop-2-uber/2.8.3-10.0/flink-shaded-hadoop-2-uber-2.8.3-10.0.jar) 
- 获取最新 master 分支并使用 JKD8 及 `mvn clean install -Dmaven.test.skip=true -Pflink-1.14` [编译](https://nightlies.apache.org/flink/flink-table-store-docs-master/docs/engines/build/) FTS release-0.3 版本

上述步骤完成后，lib 目录结构如图所示  
```
lib
├── flink-csv-1.14.5.jar
├── flink-dist_2.11-1.14.5.jar
├── flink-json-1.14.5.jar
├── flink-shaded-hadoop-2-uber-2.8.3-10.0.jar
├── flink-shaded-zookeeper-3.4.14.jar
├── flink-sql-connector-mysql-cdc-2.2.1.jar
├── flink-table-store-dist-0.2-SNAPSHOT.jar
├── flink-table_2.11-1.14.5.jar
├── log4j-1.2-api-2.17.1.jar
├── log4j-api-2.17.1.jar
├── log4j-core-2.17.1.jar
└── log4j-slf4j-impl-2.17.1.jar
```

### 第三步：修改 flink-conf 配置文件并启动集群
`vim flink-1.14.5/conf/flink-conf.yaml` 文件，按如下配置修改
```yaml
jobmanager.memory.process.size: 4096m
taskmanager.memory.process.size: 4096m
taskmanager.numberOfTaskSlots: 10
parallelism.default: 2
execution.checkpointing.interval: 1min
state.backend: rocksdb
state.backend.incremental: true
jobmanager.execution.failover-strategy: region
execution.checkpointing.checkpoints-after-tasks-finish.enabled: true
```

- 注：若想观察 FTS 的异步合并、提交即流读等信息，可以在 `flink-1.14.5/conf` 目录下修改 log4j.properties 文件，按需增加如下配置
    ```
    # Log FTS
    logger.commit.name = org.apache.flink.table.store.file.operation.FileStoreCommitImpl
    logger.commit.level = DEBUG

    logger.compaction.name = org.apache.flink.table.store.file.mergetree.compact
    logger.compaction.level = DEBUG

    logger.enumerator.name = org.apache.flink.table.store.connector.source.ContinuousFileSplitEnumerator
    logger.enumerator.level = DEBUG
    ```
这里我们只开启提交记录的 DEBUG，然后在 `flink-1.14.5` 目录下执行 `./bin/start-cluster.sh`

### 第四步：初始化表 schema 并启动 Flink SQL CLI
在 `flink-1.14.5` 目录下新建 `schema.sql` 文件，配置用例所需表的 schema 和 FTS Catalog 作为 init sql
```sql
-- 设置使用流模式
SET 'execution.runtime-mode' = 'streaming';

-- 创建并使用 FTS Catalog
CREATE CATALOG `table_store` WITH (
    'type' = 'table-store',
    'warehouse' = '/tmp/table-store-101'
);

USE CATALOG `table_store`;

-- ODS table schema

-- 注意在 FTS Catalog 下，创建使用其它连接器的表时，需要将表声明为临时表
CREATE TEMPORARY TABLE `ods_lineitem` (
  `l_orderkey` INT NOT NULL,
  `l_partkey` INT NOT NULL,
  `l_suppkey` INT NOT NULL,
  `l_linenumber` INT NOT NULL,
  `l_quantity` DECIMAL(15, 2) NOT NULL,
  `l_extendedprice` DECIMAL(15, 2) NOT NULL,
  `l_discount` DECIMAL(15, 2) NOT NULL,
  `l_tax` DECIMAL(15, 2) NOT NULL,
  `l_returnflag` CHAR(1) NOT NULL,
  `l_linestatus` CHAR(1) NOT NULL,
  `l_shipdate` DATE NOT NULL,
  `l_commitdate` DATE NOT NULL,
  `l_receiptdate` DATE NOT NULL,
  `l_shipinstruct` CHAR(25) NOT NULL,
  `l_shipmode` CHAR(10) NOT NULL,
  `l_comment` VARCHAR(44) NOT NULL,
  PRIMARY KEY (`l_orderkey`, `l_linenumber`) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc',
  'hostname' = '127.0.0.1', -- 如果想使用 host，可以修改宿主机 /etc/hosts 加入 127.0.0.1 mysql.docker.internal
  'port' = '3307',
  'username' = 'flink',
  'password' = 'flink',
  'database-name' = 'tpch_s10',
  'table-name' = 'lineitem'
);


-- DWD table schema
-- 以 `l_shipdate` 为业务日期，创建以 `l_year` 分区的表，注意所有 partition key 都需要声明在 primary key 中
CREATE TABLE IF NOT EXISTS `dwd_lineitem` (
  `l_orderkey` INT NOT NULL,
  `l_partkey` INT NOT NULL,
  `l_suppkey` INT NOT NULL,
  `l_linenumber` INT NOT NULL,
  `l_quantity` DECIMAL(15, 2) NOT NULL,
  `l_extendedprice` DECIMAL(15, 2) NOT NULL,
  `l_discount` DECIMAL(15, 2) NOT NULL,
  `l_tax` DECIMAL(15, 2) NOT NULL,
  `l_returnflag` CHAR(1) NOT NULL,
  `l_linestatus` CHAR(1) NOT NULL,
  `l_shipdate` DATE NOT NULL,
  `l_commitdate` DATE NOT NULL,
  `l_receiptdate` DATE NOT NULL,
  `l_shipinstruct` CHAR(25) NOT NULL,
  `l_shipmode` CHAR(10) NOT NULL,
  `l_comment` VARCHAR(44) NOT NULL,
  `l_year` BIGINT NOT NULL,
  PRIMARY KEY (`l_orderkey`, `l_linenumber`, `l_year`) NOT ENFORCED
) PARTITIONED BY (`l_year`) WITH (
  -- 每个 partition 下设置 2 个 bucket
  'bucket' = '2',
  -- 设置 changelog-producer 为 'input'，这会使得上游 CDC Source 不丢弃 update_before，并且下游消费 dwd_lineitem 时没有 changelog-normalize 节点
  'changelog-producer' = 'input'
);

-- ADS table schema
-- 基于 TPC-H Q1，对已发货的订单，根据订单状态和收货状态统计订单数、商品数、总营业额、总利润、平均出厂价、平均折扣价、平均折扣含税价等指标
CREATE TABLE IF NOT EXISTS `ads_pricing_summary_report` (
  `l_returnflag` CHAR(1) NOT NULL,
  `l_linestatus` CHAR(1) NOT NULL,
  `sum_quantity` DOUBLE NOT NULL,
  `sum_base_price` DOUBLE NOT NULL,
  `sum_discount_price` DOUBLE NOT NULL,
  `sum_charge_vat_inclusive` DOUBLE NOT NULL,
  `avg_quantity` DOUBLE NOT NULL,
  `avg_base_price` DOUBLE NOT NULL,
  `avg_discount` DOUBLE NOT NULL,
  `count_order` BIGINT NOT NULL
) WITH (
  'bucket' = '2'
);

-- 基于 TPC-H Q6，通过特定的销量和折扣过滤出一批商品，如果对其取消折扣，能在多大程度上降低成本，提升利润
CREATE TABLE IF NOT EXISTS `ads_potential_revenue_improvement_report` (
  `potential_revenue` DOUBLE NOT NULL
) WITH (
  'bucket' = '1'
);
```
然后运行 SQL CLI
```bash
./bin/sql-client.sh -i schema.sql
```
![flink sql cli](./pictures/start-sql-cli.png)

### 第五步：提交作业

- 任务1：通过 Flink MySQL CDC 同步 `ods_lineitem` 到 `dwd_lineitem`
  ```sql
  -- 设置作业名
  SET 'pipeline.name' = 'dwd_lineitem';
  INSERT INTO dwd_lineitem
  SELECT
    `l_orderkey`,
    `l_partkey`,
    `l_suppkey`,
    `l_linenumber`,
    `l_quantity`,
    `l_extendedprice`,
    `l_discount`,
    `l_tax`,
    `l_returnflag`,
    `l_linestatus`,
    `l_shipdate`,
    `l_commitdate`,
    `l_receiptdate`,
    `l_shipinstruct`,
    `l_shipmode`,
    `l_comment`,
    YEAR(`l_shipdate`) AS `l_year`
  FROM `ods_lineitem`;
  ```

- 任务2：写入结果表 `ads_pricing_summary_report`
  ```sql
  -- 设置作业名
  SET 'pipeline.name' = 'ads_pricing_summary_report';
  INSERT INTO `ads_pricing_summary_report`
  SELECT 
    `l_returnflag`,
    `l_linestatus`,
    SUM(`l_quantity`) AS `sum_quantity`,
    SUM(`l_extendedprice`) AS `sum_base_price`,
    SUM(`l_extendedprice` * (1-`l_discount`)) AS `sum_discount_price`, -- aka revenue
    SUM(`l_extendedprice` * (1-`l_discount`) * (1+`l_tax`)) AS `sum_charge_vat_inclusive`,
    AVG(`l_quantity`) AS `avg_quantity`,
    AVG(`l_extendedprice`) AS `avg_base_price`,
    AVG(`l_discount`) AS `avg_discount`,
    COUNT(*) AS `count_order`
  FROM `dwd_lineitem`
  WHERE `l_year` <= 1998
  AND `l_shipdate` <= DATE '1998-12-01' - INTERVAL '90' DAY
  GROUP BY  
    `l_returnflag`,
    `l_linestatus`;
  ```

-- 任务3：写入结果表 `ads_potential_revenue_improvement_report`
```sql
  SET 'pipeline.name' = 'ads_potential_revenue_improvement_report';
  -- 设置作业并发
  SET 'parallelism.default' = '1';
  INSERT INTO `ads_potential_revenue_improvement_report`
  SELECT 
    SUM(`l_extendedprice` * `l_discount`) AS `revenue`
  FROM `dwd_lineitem`
  WHERE `l_year` = 1994
  AND l_discount BETWEEN 0.06 - 0.01 AND 0.06 + 0.01 AND l_quantity < 24;
```
### 第六步：执行 Ad-hoc query
- 方式一: 批量查询  
  切换到 batch 模式执行 static query, 可以多运行几次来查看结果变化（注：查询间隔应大于所查上游表的 checkpoint 间隔）
  - 查询 Q1
    1. 切换到 batch 模式  
      `SET 'execution.runtime-mode' = 'batch';`
    2. 将结果展示切换为 `tableau` 模式  
      `SET 'sql-client.execution.result-mode' = 'tableau';`
    3. 设置作业名
      `SET 'pipeline.name' = 'Batch Query on Pricing Summary Report';`
    4. 执行查询  
      `SELECT * FROM ads_pricing_summary_report;`
  - 查询 Q6
    1. 切换到 batch 模式  
      `SET 'execution.runtime-mode' = 'batch';`
    2. 将结果展示切换为 `tableau` 模式  
      `SET 'sql-client.execution.result-mode' = 'tableau';`
    3. 设置作业并发为 1  
      `SET 'parallelism.default' = '1';`
    4. 设置作业名
      `SET 'pipeline.name' = 'Batch Query on Potential Revenue Report';`
    5. 执行查询  
      `SELECT * FROM ads_potential_revenue_improvement_report;`

- 方式二：流式查询  
  在 streaming 模式下同时查询 Q1 和 Q6 需要两个 SQL CLI
  在 `/flink` 目录下执行 `./bin/sql-client.sh -i schema.sql` 打开第二个 CLI
- 在两个 CLI 下 分别执行
  ```sql
  SET 'sql-client.execution.result-mode' = 'table';
  SET 'execution.runtime-mode' = 'streaming';
  SET 'pipeline.name' = 'Streaming Query on Pricing Summary Report';
  SET 'parallelism.default' = '2';
  SELECT * FROM ads_pricing_summary_report;
  ```
  ```sql
  SET 'sql-client.execution.result-mode' = 'table';
  SET 'execution.runtime-mode' = 'streaming';
  SET 'pipeline.name' = 'Streaming Query on Potential Revenue Report';
  SET 'parallelism.default' = '1';
  SELECT * FROM ads_potential_revenue_improvement_report;
  ```

### 第七步：结束 Demo & 释放资源
1. 执行 `exit;` 退出 Flink SQL CLI
2. 在 `flink-1.14.5` 下执行 `./bin/stop-cluster.sh` 停止 Flink 集群
3. 在 `table-store-101/real-time-update` 目录下执行 
    ```bash
    docker-compose down && docker rmi real-time-update_mysql-101 && docker volume prune && docker builder prune
    ```
    注意：请自行判断是否要增加 `-f` 来强制执行 `prune`
4. 执行 `rm -rf /tmp/table-store-101`   