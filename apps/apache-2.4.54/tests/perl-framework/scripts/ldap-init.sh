#!/bin/bash -ex
DOCKER=${DOCKER:-`which docker 2>/dev/null || which podman 2>/dev/null`}
cid1=`${DOCKER} run -d -p 8389:389 httpd_ldap`
cid2=`${DOCKER} run -d -p 8390:389 httpd_ldap`
sleep 5

# For the CentOS slapd configuration, load some default schema:
if ${DOCKER} exec -i $cid1 test -f /etc/centos-release; then
    ${DOCKER} exec -i $cid1 /usr/bin/ldapadd -Y EXTERNAL -H ldapi:// < scripts/slapd-config.ldif
    ${DOCKER} exec -i $cid2 /usr/bin/ldapadd -Y EXTERNAL -H ldapi:// < scripts/slapd-config.ldif

    for sc in cosine inetorgperson nis; do
       fn=/etc/openldap/schema/${sc}.ldif
       ${DOCKER} exec -i $cid1 /usr/bin/ldapadd -Y EXTERNAL -H ldapi:// -f ${fn}
       ${DOCKER} exec -i $cid2 /usr/bin/ldapadd -Y EXTERNAL -H ldapi:// -f ${fn}
    done

    ldapadd -x -H ldap://localhost:8390 -D cn=admin,dc=example,dc=com -w travis < scripts/suffix.ldif
    ldapadd -x -H ldap://localhost:8389 -D cn=admin,dc=example,dc=com -w travis < scripts/suffix.ldif
fi

# Disable anonymous bind; must be done as an authenticated local user
# hence via ldapadd -Y EXTERNAL within the container.
${DOCKER} exec -i $cid1 /usr/bin/ldapadd -Y EXTERNAL -H ldapi:// < scripts/non-anon.ldif
${DOCKER} exec -i $cid2 /usr/bin/ldapadd -Y EXTERNAL -H ldapi:// < scripts/non-anon.ldif

ldapadd -x -H ldap://localhost:8389 -D cn=admin,dc=example,dc=com -w travis < scripts/httpd.ldif
ldapadd -x -H ldap://localhost:8390 -D cn=admin,dc=example,dc=com -w travis < scripts/httpd-sub.ldif
