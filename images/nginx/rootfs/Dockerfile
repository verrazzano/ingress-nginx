# Copyright 2015 The Kubernetes Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Copyright (C) 2020, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

FROM container-registry.oracle.com/os/oraclelinux:8-slim@sha256:65343e6b87ef30945a6e418c66ad3efbe6eed7437cf685cf0cdc1cbfb0f2168d AS builder

COPY . /
COPY oracle-epel-ol8.repo /etc/yum.repos.d/
COPY oracle-codeready-ol8.repo /etc/yum.repos.d/

RUN /build.sh

# Use a multi-stage build
FROM container-registry.oracle.com/os/oraclelinux:8-slim@sha256:65343e6b87ef30945a6e418c66ad3efbe6eed7437cf685cf0cdc1cbfb0f2168d

COPY stage-licenses/* /license/

ENV PATH=$PATH:/usr/local/luajit/bin:/usr/local/nginx/sbin:/usr/local/nginx/bin

ENV LUA_PATH="/usr/local/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/lib/lua/?.lua;;"
ENV LUA_CPATH="/usr/local/lib/lua/?/?.so;/usr/local/lib/lua/?.so;;"

COPY oracle-epel-ol8.repo /etc/yum.repos.d/
COPY addgroup /usr/sbin/
COPY adduser /usr/sbin/
COPY dumb-init /usr/bin/

COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt /opt
COPY --from=builder /etc/nginx /etc/nginx

RUN microdnf install  \
    openssl \
    pcre \
    zlib \
    lmdb \
    curl ca-certificates \
    patch \
    yajl \
    libyaml \
    libxml2 \
    libmaxminddb \
    nano \
    tzdata \
    pkg-config \
  && rpm -i https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/GeoIP-1.5.0-13.el7.x86_64.rpm \
  && rpm -i https://yum.oracle.com/repo/OracleLinux/OL7/optional/developer/x86_64/getPackage/GeoIP-devel-1.5.0-13.el7.x86_64.rpm \
  && chmod +x /usr/bin/dumb-init \
  && ln -s /usr/local/nginx/sbin/nginx /sbin/nginx \
  && ln -s /usr/local/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2 \
  && addgroup -Sg 101 www-data \
  && adduser -S -D -H -u 101 -h /usr/local/nginx \
    -s /sbin/nologin -G www-data -g www-data www-data \
  && bash -eu -c ' \
  writeDirs=( \
    /var/log/nginx \
    /var/lib/nginx/body \
    /var/lib/nginx/fastcgi \
    /var/lib/nginx/proxy \
    /var/lib/nginx/scgi \
    /var/lib/nginx/uwsgi \
    /var/log/audit \
  ); \
  for dir in "${writeDirs[@]}"; do \
    mkdir -p ${dir}; \
    chown -R www-data.www-data ${dir}; \
  done'

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
