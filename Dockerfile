FROM debian:stretch-slim

# Update apt database and install necessary packages.
RUN apt-get update -qq
RUN apt-get install -qq apt-transport-https curl fuse git gnupg golang sudo

# Set up the gcsfuse fuse module repo.
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-stretch main" > /etc/apt/sources.list.d/gcsfuse.list
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
RUN apt-get update -qq
RUN apt-get install -qq gcsfuse

# Install snmp_exporter.
RUN GOPATH=/root/go go get github.com/prometheus/snmp_exporter

RUN mkdir /etc/snmp_exporter

EXPOSE 9116

# Mount the GCS bucket that contains the snmp_exporter config and then start
# snmp_exporter.
CMD gcsfuse switch-config-mlab-sandbox /etc/snmp_exporter && /root/go/bin/snmp_exporter --config.file=/etc/snmp_exporter/snmp_exporter_config.yaml
