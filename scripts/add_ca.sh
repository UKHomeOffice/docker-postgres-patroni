#!/usr/bin/env bash

set -e

if [ -n ${CA_FILE} ]; then
  [ ! -f ${CA_FILE} ] && echo "Missing cert file specified ${CA_FILE}:"
  cp ${CA_FILE} /etc/pki/ca-trust/source/anchors/
  update-ca-trust
fi