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

function log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") $@"
}

for file in `ls /tpch/dbgen/*.tbl`; do
  table=${file#*/tpch/dbgen/}
  table=${table%.*}
  log "Start to load file ${file} into table ${table}"
  time mysql --defaults-extra-file=/tpch/dbgen/mycreds.cnf -v -D ${MYSQL_DATABASE} --local-infile=1 -e "SET UNIQUE_CHECKS = 0; SET FOREIGN_KEY_CHECKS = 0;" -e "
  LOAD DATA LOCAL INFILE '${file}' INTO TABLE ${table} FIELDS TERMINATED BY '|' LINES TERMINATED BY '|\n';"
done