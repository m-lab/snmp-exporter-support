#!/bin/bash
#
# A GCE startup script to install Docker per the instructions at:
# https://docs.docker.com/engine/installation/linux/docker-ce/debian/#install-using-the-repository

apt-get update --yes
apt-get install --yes \
  apt-transport-https
  ca-certificates \
  curl \
  gnupg2 \
  software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian \
  $(lsb_release -cs) \
  stable"

apt-get update --yes
apt-get install --yes docker-ce
