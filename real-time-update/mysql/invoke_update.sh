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

set -x;

# generate one chunk at a time from chunk id 3
for chunk in `seq 3 8`; do
  echo "Start to generate ${chunk} chunk"
  /tpch/dbgen/load_data.sh ${chunk} ${chunk}
  echo "Start to load ${chunk} chunk"
  time mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -v --local-infile=1 -e "SET UNIQUE_CHECKS = 0;" -e "
  LOAD DATA LOCAL INFILE '/tpch/dbgen/lineitem.tbl.${chunk}' INTO TABLE lineitem FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';"
  sleep 1m
done