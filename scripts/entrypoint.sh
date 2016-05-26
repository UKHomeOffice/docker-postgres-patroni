#!/bin/bash

set -e

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SECRETS_DIR=/var/lib/pgsql/secrets
DATA_DIR=${DATA_DIR:-/var/lib/pgsql/data}
ETCD_PROTOCOL=${ETCD_PROTOCOL:-http}
ETCD_PORT=${ETCD_PORT:-2379}

function get_config() {

  conf_name="${1}"
  conf_file="${SECRETS_DIR}/${conf_name}"
  if [ -f ${conf_file} ]; then
    echo "Using config from ${conf_file}"
    value="$(cat ${conf_file})"
  else
    value="${!conf_name}"
  fi
  if [ ! -z ${value} ]; then
    eval "export ${conf_name}=${value}"
  fi
}

if [ "$(whoami)" != "${PGUSER}" ]; then
  # Steps to carry out before switching to un-privileged user

  echo "Fixing permissions..."
  /scripts/fix-permissions.sh ${DATA_DIR}

  echo "Adding CA..."
  /scripts/add_ca.sh

  echo "Switching user..."
  su ${PGUSER} --preserve-environment -c "${BASH_SOURCE[0]} $@"
  exit $?
else
  echo "Running as $(whoami)"
fi

for file in ${SECRETS_DIR}/* ; do
  get_config $(basename ${file})
done

# if in a pod, set IP to the pod IP, otherwise
# set it to the hostname
if [ -z "${POD_IP}" ]; then
  echo "no pods\n"
  DOCKER_IP=$(hostname --ip-address)
  HNAME=$(hostname)
  echo "$DOCKER_IP $NODE"
else
  DOCKER_IP=$($POD_IP)
  HNAME=$($POD_NAME)
fi

NODE=${HNAME//[^a-z0-9]/_}

# create patroni config
cat > /etc/patroni/patroni.yml <<__EOF__

scope: &scope ${CLUSTER}
ttl: &ttl 30
loop_wait: &loop_wait 10
restapi:
  listen: ${DOCKER_IP}:8001
  connect_address: ${DOCKER_IP}:8001
  auth: '${APIUSER}:${APIPASS}'
  certfile: /etc/ssl/certs/patroni.cert
  keyfile: /etc/ssl/certs/patroni.cert
etcd:
  scope: *scope
  ttl: *ttl
  host: ${ETCD}:${ETCD_PORT}
  protocol: ${ETCD_PROTOCOL}
tags:
  nofailover: False
  noloadbalance: False
  clonefrom: False
postgresql:
  name: ${NODE}
  scope: *scope
  listen: 0.0.0.0:5432
  connect_address: ${DOCKER_IP}:5432
  data_dir: ${DATA_DIR}
  maximum_lag_on_failover: 104857600 # 100 megabyte in bytes
  use_slots: True
  pgpass: /tmp/pgpass0
  initdb:
  - encoding: UTF8
  - data-checksums
  create_replica_methods:
  - basebackup
  pg_hba:
  - host all all 0.0.0.0/0 trust
  - # hostssl all all 0.0.0.0/0 trust
  - host replication ${ADMINUSER} ${DOCKER_IP}/16    md5
  replication:
    username: ${ADMINUSER}
    password: ${ADMINPASS}
    network:  ${DOCKER_IP}/16
  pg_rewind:
    username: ${ADMINUSER}
    password: ${ADMINPASS}
  superuser:
    username: ${ADMINUSER}
    password: ${ADMINPASS}
  admin:
    username: ${ADMINUSER}
    password: ${ADMINPASS}
  parameters:
    archive_mode: "off"
    # archive_command: 'true'
    listen_addresses: 0.0.0.0
    archive_command: mkdir -p ../wal_archive && cp %p ../wal_archive/%f
    wal_level: hot_standby
    max_wal_senders: 10
    hot_standby: "on"
__EOF__

# do 9.3 compatibility which removes replication slots
if [ "${PGVERSION}" = "9.3" ]; then
    cat >> /etc/patroni/patroni.yml <<__EOF__
    wal_keep_segments: 10
__EOF__
else
    cat >> /etc/patroni/patroni.yml <<__EOF__
    max_replication_slots: 7
    wal_keep_segments: 5
__EOF__
fi

cat /etc/patroni/patroni.yml

exec python /patroni/patroni.py /etc/patroni/patroni.yml
