#!/usr/bin/bash
###############################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

 mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -v -e "
    SET GLOBAL local_infile=true;
    DROP DATABASE IF EXISTS ${MYSQL_DATABASE};
    CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

    USE ${MYSQL_DATABASE};

    CREATE USER 'flink' IDENTIFIED WITH mysql_native_password BY 'flink';

    GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'flink';

    FLUSH PRIVILEGES;

    CREATE TABLE nation  (  
        n_nationkey  INTEGER NOT NULL,
        n_name       CHAR(25) NOT NULL,
        n_regionkey  INTEGER NOT NULL,
        n_comment    VARCHAR(152)) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    CREATE TABLE customer ( 
        c_custkey     INTEGER NOT NULL,
        c_name        VARCHAR(25) NOT NULL,
        c_address     VARCHAR(40) NOT NULL,
        c_nationkey   INTEGER NOT NULL,
        c_phone       CHAR(15) NOT NULL,
        c_acctbal     DECIMAL(15,2) NOT NULL,
        c_mktsegment  CHAR(10) NOT NULL,
        c_comment     VARCHAR(117) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    CREATE TABLE orders  (  
        o_orderkey       INTEGER NOT NULL,
        o_custkey        INTEGER NOT NULL,
        o_orderstatus    CHAR(1) NOT NULL,
        o_totalprice     DECIMAL(15,2) NOT NULL,
        o_orderdate      DATE NOT NULL,
        o_orderpriority  CHAR(15) NOT NULL,  
        o_clerk          CHAR(15) NOT NULL, 
        o_shippriority   INTEGER NOT NULL,
        o_comment        VARCHAR(79) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    -- Add PK Constraint

    ALTER TABLE nation ADD PRIMARY KEY (n_nationkey);

    ALTER TABLE customer ADD PRIMARY KEY (c_custkey);

    ALTER TABLE orders ADD PRIMARY KEY (o_orderkey);

    -- Add FK Constraint

    ALTER TABLE customer ADD FOREIGN KEY customer_fk1 (c_nationkey) REFERENCES nation(n_nationkey);

    ALTER TABLE orders ADD FOREIGN KEY orders_fk1 (o_custkey) REFERENCES customer(c_custkey);
    
    -- Disable check
    SET UNIQUE_CHECKS = 0;"