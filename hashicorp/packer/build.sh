#!/bin/bash

CLOUD=${1:-sandbox}
TARGET=${2}

if [[ $TARGET ]]; then
  echo "########################################################"
  echo "# Building ${TARGET} on with vars/${CLOUD}/pkrvars.hcl #"
  echo "########################################################"
  packer build -only="amazon-ebs.${TARGET}_server" -var-file="vars/${CLOUD}.pkrvars.hcl" .
else
  echo "##################################################"
  echo "# Building all on with vars/${CLOUD}/pkrvars.hcl #"
  echo "##################################################"
  packer build -var-file="vars/${CLOUD}.pkrvars.hcl" .
fi
