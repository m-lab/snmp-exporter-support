#!/bin/bash

set -e
set -u
set -x

# These variables will likely not change.
USAGE="Usage: $0 <project>"
PROJECT=${1:?Please provide project name: $USAGE}
CREDS_FILE="snmp-exporter-service-account.json"
SCP_FILES="Dockerfile mlab.yml"
EXPORTER_URI=$(cut -d' ' -f2 Dockerfile)

# These variables will change depending on the GCE instance created.
GCE_INSTANCE="kinkade-snmp-exporter"
GCE_ZONE="us-central1-a"

# Add gcloud to PATH.
source "${HOME}/google-cloud-sdk/path.bash.inc"

# Generate the snmp_exporter configuration file.
./gen-snmp_exporter-config.py

# Set the project and zone for all future gcloud commands.
gcloud config set project $PROJECT
gcloud config set compute/zone $GCE_ZONE

# Authenticate the service account using the JSON credentials file.
if [[ -f "${CREDS_FILE}" ]] ; then
  gcloud auth activate-service-account --key-file ${CREDS_FILE}
else
  echo "Service account credentials not found at ${CREDS_FILE}!"
  exit 1
fi

# Make sure that the files we want to copy actually exist.
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
gcloud compute ssh $GCE_INSTANCE --command \
  "sudo docker rm -f \$(sudo docker ps -q -f=ancestor=$EXPORTER_URI)"

# Start a new container based on the new/updated image
gcloud compute ssh $GCE_INSTANCE --command \
  "sudo docker run -p 9116:9116 -d ${EXPORTER_URI}"
