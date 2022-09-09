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

table_name=${TABLE_NAME}

if [[ ${STAGE} == "update" && ${UPDATE_TYPE} == "upsert" ]]; then
    table_name="update_${TABLE_NAME}"
elif [[ ${STAGE} == "update" && ${UPDATE_TYPE} == "delete" ]]; then
    table_name="delete_${TABLE_NAME}"    
fi

time mysql -uroot -p${MYSQL_ROOT_PASSWORD} -hlocalhost ${MYSQL_DATABASE} --local_infile=1 -e "USE ${MYSQL_DATABASE}" -e "
    LOAD DATA LOCAL INFILE '${FILE_NAME}'
    IGNORE INTO TABLE ${table_name}
    FIELDS TERMINATED BY '|'
    LINES TERMINATED BY '|\n';" 