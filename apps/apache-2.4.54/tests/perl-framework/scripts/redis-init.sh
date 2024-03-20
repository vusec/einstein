#!/bin/bash -ex
DOCKER=${DOCKER:-`which docker 2>/dev/null || which podman 2>/dev/null`}
${DOCKER} build -t httpd_redis - <<EOF
FROM quay.io/centos/centos:stream8
RUN yum install -y redis
CMD /usr/bin/redis-server
EOF
${DOCKER} run -d -p 6379:6379 httpd_redis
