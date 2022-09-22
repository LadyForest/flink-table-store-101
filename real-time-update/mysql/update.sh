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

# check mysql status
echo "$(date +"%Y-%m-%d %H:%M:%S") Wait MySQL to start..."
sleep ${SF}m
while status=$(mysqladmin ping -uroot -p${MYSQL_ROOT_PASSWORD} -hlocalhost); [ "${status}" != "mysqld is alive" ]; do
  echo "$(date +"%Y-%m-%d %H:%M:%S") Wait MySQL to start..."
  sleep 2m
done

while num_records=$(mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} -se "SELECT COUNT(1) FROM lineitem"); [ "${num_records}" -eq ${TOTAL_RECORDS} ]; do
  echo "$(date +"%Y-%m-%d %H:%M:%S") Wait MySQL to finish loading data..."
  sleep 2m
done

echo "Refresh Function will be applied after ${WAIT_FOR_UPDATE}"
sleep ${WAIT_FOR_UPDATE}

# generate continuous updates as long as the container is running, start with [1, 100], then [101, 200], [201, 300]...
echo "$(date +"%Y-%m-%d %H:%M:%S") Start to apply New Sales Refresh Function (RF1) and Old Sales Refresh Function (RF2) in infinite loop"

start_pair=1
total_pair=100
while :
do
  echo "$(date +"%Y-%m-%d %H:%M:%S") TPC-H Population Generator (Version 3.0.0) starts to generate update set with sf = ${SF} and total pair = ${total_pair}"
  ./dbgen -q -f -s ${SF} -U ${total_pair}
  for i in `seq ${start_pair} ${total_pair}`; do
    if [[ `expr ${i} % 10` -eq 0 ]]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") Start to apply New Sales Refresh Function (RF1) for pair ${i}"
    fi
    # This refresh function adds new sales information to the database.
    mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} -e "TRUNCATE update_lineitem"
    mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} --local-infile=1 -e "SET UNIQUE_CHECKS = 0;" -e "
    LOAD DATA LOCAL INFILE '/tpch/dbgen/lineitem.tbl.u${i}' INTO TABLE update_lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';"
    mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} -e "
        BEGIN;
        INSERT INTO lineitem
        SELECT * FROM update_lineitem;
        COMMIT;"

    sleep 10s

    if [[ `expr ${i} % 10` -eq 0 ]]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") Start to apply Old Sales Refresh Function (RF2) for pair ${i}"
    fi
    # This refresh function removes old sales information from the database.
    mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} -e "TRUNCATE delete_lineitem"
    mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} --local-infile=1 -e "SET UNIQUE_CHECKS = 0;" -e "
    LOAD DATA LOCAL INFILE '/tpch/dbgen/delete.${i}' INTO TABLE delete_lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';"
    mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} -e "
        BEGIN;
        DELETE FROM lineitem WHERE l_orderkey IN (SELECT l_orderkey FROM delete_lineitem);
        COMMIT;"
  done

  num_records=$(mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -D ${MYSQL_DATABASE} -se "SELECT COUNT(1) FROM lineitem") 
  echo "$(date +"%Y-%m-%d %H:%M:%S") Finish update sets from ${start_pair} to ${total_pair}, current #(record) is ${num_records}"
  start_pair=`expr ${total_pair} + 1`
  total_pair=`expr ${total_pair} \* 2`

  sleep 2m
done