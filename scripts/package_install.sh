#!/bin/bash

set -e

yum clean all
localedef -f UTF-8 -i en_US en_US.UTF-8
mkdir -p /var/lib/pgsql/data
yum install -y centos-release-scl epel-release

# install some basics
yum -y -q install readline-devel
yum -y -q install hostname

# setup yum to pull PostgreSQL from yum.postgresql.org
rpm -Uvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm
# install postgresql and a bunch of accessories
yum -y -q install postgresql95
yum -y -q install postgresql95-server
yum -y -q install postgresql95-contrib
yum -y -q install postgresql95-devel postgresql95-libs
yum -y -q install python-psycopg2

test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)"

# set up SSL certs
yum -y -q install openssl openssl-devel
sh /etc/ssl/certs/make-dummy-cert /etc/ssl/certs/patroni.cert
chown postgres:postgres /etc/ssl/certs/patroni.cert

# put pg_ctl in postgres' path
ln -s /usr/pgsql-9.5/bin/pg_ctl /usr/bin/
ln -s /usr/pgsql-9.5/bin/pg_config /usr/bin/
ln -s /usr/pgsql-9.5/bin/pg_controldata /usr/bin/

#  install extensions
#yum -y -q install postgresql-${PGVER}-postgis-2.1 postgresql-${PGVER}-postgis-2.1-scripts

# install python requirements
yum -y -q install python-pip
yum -y -q install python-devel

# install cert management:
yum -y -q install ca-certificates

# install WAL-E
# pip install -U six
# pip install -U requests
# pip install -U wal-e
# yum -y -q install daemontools
# yum -y -q install lzop pv

# install patroni dependancies
# yum -y -q install python-y
pip install -U setuptools
pip install -r /scripts/requirements-py2.txt

# install patroni.  commented out for testing
cd /patroni
python setup.py install
