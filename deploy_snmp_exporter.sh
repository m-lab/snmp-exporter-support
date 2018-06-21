#!/bin/bash

set -e
set -u
set -x

# These variables should not change much
USAGE="Usage: $0 <project>"
PROJECT=${1:?Please provide project name: $USAGE}
KEYNAME=${2:?Please provide an authentication key name: $USAGE}

SCP_FILES="Dockerfile"
IMAGE_TAG="m-lab/prometheus-snmp-exporter"
GCE_ZONE="us-central1-a"
GCE_NAME="snmp-exporter"
GCE_IP_NAME="snmp-exporter-public-ip"
GCE_IMG_PROJECT="cos-cloud"
GCE_IMG_FAMILY="cos-stable"
GCS_BUCKET="snmp-exporter-${PROJECT}"

# Add gcloud to PATH.
source "${HOME}/google-cloud-sdk/path.bash.inc"

# Add m-lab/travis help lib
source "$TRAVIS_BUILD_DIR/travis/gcloudlib.sh"

# Set the project and zone for all future gcloud commands.
gcloud config set project $PROJECT
gcloud config set compute/zone $GCE_ZONE

# Authenticate the service account using KEYNAME.
activate_service_account "${KEYNAME}"

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
  --image-project $GCE_IMG_PROJECT --image-family $GCE_IMG_FAMILY \
  --tags ${GCE_NAME}

# Give the GCE instance another 30s to fully become available. From time to time
# the Travis-CI build fails because it can't connect via SSH.
sleep 30

# Get the internal VPC IP of the new instance.
INTERNAL_IP=$(gcloud compute instances list \
  --format="value(networkInterfaces[0].networkIP)" \
  --filter="name=${GCE_NAME}")

# Copy required snmp_exporter files to the GCE instance.
gcloud compute scp $SCP_FILES $GCE_NAME:~

# Build the snmp_exporter Docker container.
gcloud compute ssh $GCE_NAME --command "docker build --tag ${IMAGE_TAG} ."

# Start a new container based on the new/updated image.  The SYS_ADMIN
# capability is needed here, along with access to /dev/fuse, because the
# container needs to mount the GCS bucket that contains the snmp_exporter config
# file. There is a possibility that a finer-grained capability exists that will
# allow a container to mount a filesystem, but SYS_ADMIN is the one that I found
# people recommending.
gcloud compute ssh $GCE_NAME --command "docker run --detach --publish ${INTERNAL_IP}:9116:9116 --name ${GCE_NAME} --cap-add SYS_ADMIN --device /dev/fuse --security-opt apparmor:unconfined --env PROJECT=${PROJECT} ${IMAGE_TAG}"

# Run Prometheus node_exporter in a container so we can gather VM metrics.
gcloud compute ssh $GCE_NAME --command "docker run --detach --publish ${INTERNAL_IP}:9100:9100 --name node-exporter --volume /proc:/host/proc --volume /sys:/host/sys prom/node-exporter --path.procfs /host/proc --path.sysfs /host/sys --no-collector.arp --no-collector.bcache --no-collector.conntrack --no-collector.edac --no-collector.entropy --no-collector.filefd --no-collector.hwmon --no-collector.infiniband --no-collector.ipvs --no-collector.mdadm --no-collector.netstat --no-collector.sockstat --no-collector.time --no-collector.timex --no-collector.uname --no-collector.vmstat --no-collector.wifi --no-collector.xfs --no-collector.zfs"
