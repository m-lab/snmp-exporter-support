#!/bin/bash

set -e
set -u
set -x

USAGE="Usage: $0 <project>"
PROJECT=${1:?Please provide project name: $USAGE}
GCE_INSTANCE="kinkade-snmp-exporter"
GCE_ZONE="us-central1-a"
CREDS_FILE="snmp-exporter-service-account.json"
SCP_FILES="Dockerfile mlab.yml"
SNMP_EXPORTER_VERSION="v0.6.0"

# Generate the snmp_exporter configuration file.
./gen-snmp_exporter-config.py

# Set the project and zone for all future gcloud commands.
gcloud config set project $PROJECT
gcloud config set compute/zone $GCE_ZONE

# Authenticate using the given service account.
if [[ -f "${CREDS_FILE}" ]] ; then
  gcloud auth activate-service-account --key-file ${CREDS_FILE}
else
  echo "Service account key not found at ${CREDS_FILE}!"
  exit 1
fi

for scp_file in ${SCP_FILES}; do
  if [[ ! -f "${scp_file}" ]]; then
    echo "Missing required file: ${scp_file}!"
    exit 1
  fi
done

# Copy required snmp_exporter files to the GCE instance
gcloud compute scp $SCP_FILES $GCE_INSTANCE:~

# Build the snmp_exporter Docker container
gcloud compute ssh $GCE_INSTANCE --command "sudo docker build ."
# Delete any existing snmp_exporter containters
gcloud compute ssh $GCE_INSTANCE --command "sudo docker rm --force \$(sudo docker ps -q --filter=ancestor=prom/snmp-exporter:${SNMP_EXPORTER_VERSION})"
# Start a new container based on the new images
gcloud compute ssh $GCE_INSTANCE --command "sudo docker run -p 9116:9116 -d prom/snmp-exporter:${SNMP_EXPORTER_VERSION}"
