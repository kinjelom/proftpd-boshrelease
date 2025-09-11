#!/bin/bash

deployment_name=proftpd-rnd

bosh -d ${deployment_name} deploy "manifests/proftpd-fsaa.yml" \
  -v deployment_name="${deployment_name}" \
  -o manifests/ops/attach-nfs-volume.yml \
  -o manifests/ops/fsaa-initial-test-accounts.yml \
  --vars-file="vars/${deployment_name}-vars.yml" \
  -v proftpd_instances=2 \
  --no-redact --fix

