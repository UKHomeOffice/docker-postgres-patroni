#!/bin/bash

mkdir -p /var/lib/pgsql
chown -R postgres:postgres /var/lib/pgsql
chmod -R 700 /var/lib/pgsql

mkdir /etc/patroni
mkdir /etc/patroni/conf.d
chown -R postgres:postgres /etc/patroni

mkdir /etc/wal-e.d/

#mv /setup/patroni /patroni
#chown -R postgres:postgres /patroni
#chmod +x /patroni/*.py

#mkdir /scripts
#cp /setup/scripts/* /scripts/

