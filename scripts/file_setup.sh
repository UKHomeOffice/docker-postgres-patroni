#!/bin/bash

mkdir /etc/patroni
mkdir /etc/patroni/conf.d
chown -R postgres:postgres /etc/patroni
mkdir /etc/wal-e.d/
