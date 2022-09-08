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

FROM mysql:latest
WORKDIR /tpch/dbgen/
COPY --from=iamjane/tpch-mysql:latest /tpch/dbgen/ /tpch/dbgen/
COPY ./mysql/ /tpch/dbgen/

ARG SF=1
ARG TABLE_NAME=lineitem
ARG FILE_NAME=lineitem.tbl
ARG STAGE=init
ARG UPDATE_TYPE=upsert

ENV SF=${SF}
ENV MYSQL_USER=mysqluser
ENV MYSQL_PASSWORD=mysqlpw
ENV MYSQL_DATABASE=tpch_s${SF}
ENV MYSQL_ROOT_PASSWORD=rootpw
ENV MYSQL_HOST=mysql
ENV TABLE_NAME=${TABLE_NAME}
ENV FILE_NAME=${FILE_NAME}
ENV STAGE=${STAGE}
ENV UPDATE_TYPE=${UPDATE_TYPE}

RUN cp init-db.sh load-data.sh /docker-entrypoint-initdb.d/ \
    && mv *.cnf /etc/mysql/conf.d/ \
    && mv *.sh /usr/local/bin/ \
    && chown -R mysql:mysql /tpch/dbgen/ /docker-entrypoint-initdb.d/ \
    && chmod +x /usr/local/bin/*.sh \
    && ./dbgen -v -s ${SF} -T L