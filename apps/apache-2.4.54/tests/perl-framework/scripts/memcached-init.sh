#!/bin/bash -ex
DOCKER=${DOCKER:-`which docker 2>/dev/null || which podman 2>/dev/null`}
${DOCKER} build -t httpd_memcached - <<EOF
FROM quay.io/centos/centos:stream8
RUN yum install -y memcached
CMD /usr/bin/memcached -u memcached -v
EOF
${DOCKER} run -d -p 11211:11211 httpd_memcached
