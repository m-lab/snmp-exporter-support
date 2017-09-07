#!/bin/bash

set -e
set -u
set -x

# These variables should not change much
USAGE="Usage: $0 <project>"
PROJECT=${1:?Please provide project name: $USAGE}
CREDS_FILE="snmp-exporter-service-account_${PROJECT}.json"
SCP_FILES="Dockerfile mlab.yml"
IMAGE_TAG="m-lab/prometheus-snmp-exporter"
GCE_ZONE="us-central1-a"
GCE_NAME="snmp-exporter"
GCE_IP_NAME="snmp-exporter-public-ip"
GCE_IMG_PROJECT="coreos-cloud"
GCE_IMG_FAMILY="coreos-stable"

# Add gcloud to PATH.
source "${HOME}/google-cloud-sdk/path.bash.inc"

# Generate the snmp_exporter configuration file.
$TRAVIS_BUILD_DIR/gen_snmp_exporter_config.py

# Set the project and zone for all future gcloud commands.
gcloud config set project $PROJECT
gcloud config set compute/zone $GCE_ZONE

# Authenticate the service account using the JSON credentials file.
if [[ -f "/tmp/${CREDS_FILE}" ]] ; then
  gcloud auth activate-service-account --key-file /tmp/$CREDS_FILE
else
  echo "Service account credentials not found at /tmp/${CREDS_FILE}!"
  exit 1
fi

# Make sure that the files we want to copy actually exist.
for scp_file in ${SCP_FILES}; do
  if [[ ! -f "${TRAVIS_BUILD_DIR}/${scp_file}" ]]; then
    echo "Missing required file: ${TRAVIS_BUILD_DIR}/${scp_file}!"
    exit 1
  fi
done

# Delete the existing GCE instance, if it exists. gcloud has an exit status of 0
# whether any instances are found or not. When no instances are found, a short
# message is echoed to stderr. When an instance is found a summary is echoed to
# stdout. If $EXISTING_INSTANCE is not null then we infer that the instance
# already exists.
EXISTING_INSTANCE=$(gcloud compute instances list --filter "name=${GCE_NAME}")
if [[ -n "${EXISTING_INSTANCE}" ]]; then
  gcloud compute instances delete $GCE_NAME --quiet
fi

# Create the new GCE instance. NOTE: $GCE_IP_NAME *must* refer to an existing
# static external IP address for the project.
gcloud compute instances create $GCE_NAME --address $GCE_IP_NAME \
  --image-project $GCE_IMG_PROJECT --image-family $GCE_IMG_FAMILY

# Copy required snmp_exporter files to the GCE instance.
gcloud compute scp $SCP_FILES $GCE_NAME:~

# Build the snmp_exporter Docker container.
gcloud compute ssh $GCE_NAME --command "sudo docker build -t ${IMAGE_TAG} ."

# Delete any existing snmp_exporter containters.
gcloud compute ssh $GCE_NAME --command \
  "if [[ -n \"\$(sudo docker ps -q -f=ancestor=$IMAGE_TAG)\" ]]; then \
  sudo docker rm -f \$(sudo docker ps -q -f=ancestor=$IMAGE_TAG); fi"

# Start a new container based on the new/updated image
gcloud compute ssh $GCE_NAME --command \
  "sudo docker run -p 9116:9116 -d ${IMAGE_TAG}"
