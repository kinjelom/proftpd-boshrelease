#!/bin/bash

deployment_name=proftpd-rnd

bosh -d ${deployment_name} deploy "manifests/proftpd-fsaa.yml" \
  -v deployment_name="${deployment_name}" \
  -o manifests/ops/attach-persistent-disk.yml \
  -o manifests/ops/fsaa-initial-test-accounts.yml \
  --vars-file="vars/${deployment_name}-vars.yml" \
  --no-redact --fix
