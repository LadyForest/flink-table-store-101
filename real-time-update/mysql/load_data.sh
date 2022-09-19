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

for file in `ls /tpch/dbgen/lineitem.tbl.*`; do
  echo "Start to load chunk ${file}"
  time mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} --local-infile=1 -e "SET UNIQUE_CHECKS = 0;" -e "
  LOAD DATA LOCAL INFILE '${file}' INTO TABLE lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';"
done

num_records=$(mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -se "SELECT COUNT(1) FROM lineitem") 
echo "Finish loading all chunks, current #(record) is ${num_records}, and will generate update records in 3 seconds"
sleep 3s

mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -e "
  CREATE TABLE update_lineitem LIKE lineitem;

  CREATE TABLE delete_lineitem (
    l_orderkey    INTEGER NOT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

  ALTER TABLE delete_lineitem ADD PRIMARY KEY (l_orderkey);"

./dbgen -s ${SF} -U 100
for i in `seq 1 100`; do
  echo "Start to apply New Sales Refresh Function (RF1) for pair ${i}"
  # This refresh function adds new sales information to the database.
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -e "TRUNCATE update_lineitem"
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} --local-infile=1 -e "SET UNIQUE_CHECKS = 0;" -e "
  LOAD DATA LOCAL INFILE '/tpch/dbgen/lineitem.tbl.u${i}' INTO TABLE update_lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';"
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -e "
    BEGIN;
    INSERT INTO lineitem
    SELECT * FROM update_lineitem;
    COMMIT;"
  echo "Start to apply Old Sales Refresh Function (RF2) for pair ${i}"
  # This refresh function removes old sales information from the database.
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -e "TRUNCATE delete_lineitem"
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} --local-infile=1 -e "SET UNIQUE_CHECKS = 0;" -e "
  LOAD DATA LOCAL INFILE '/tpch/dbgen/delete.${i}' INTO TABLE delete_lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';"
  mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -e "
    BEGIN;
    DELETE FROM lineitem WHERE l_orderkey IN (SELECT l_orderkey FROM delete_lineitem);
    COMMIT;" 
done
num_records=$(mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -se "SELECT COUNT(1) FROM lineitem") 
echo "Finish updating data, current #(record) is ${num_records}"