FROM debian:stretch-slim

ENV PROJECT mlab-sandbox

# Update apt database and install necessary packages.
RUN apt-get update -qq && apt-get install -qq \
    apt-transport-https \
    curl \
    fuse \
    git \
    gnupg \
    golang \
    sudo

# Set up the gcsfuse fuse module repo and install 
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-stretch main" > \
    /etc/apt/sources.list.d/gcsfuse.list
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo apt-key add -
RUN apt-get update -qq && apt-get install -qq gcsfuse

# Install snmp_exporter.
RUN GOPATH=/root/go go get github.com/prometheus/snmp_exporter

# This is the directory where the GCS bucket will be mounted.
RUN mkdir /etc/snmp_exporter

# snmp_exporter listens on 9116.
EXPOSE 9116

# Mount the GCS bucket that contains the snmp_exporter config and then start
# snmp_exporter.
CMD gcsfuse -o ro switch-config-${PROJECT} /etc/snmp_exporter && \
    /root/go/bin/snmp_exporter \
    --config.file=/etc/snmp_exporter/snmp_exporter_config.yaml
