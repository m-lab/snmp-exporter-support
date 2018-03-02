FROM debian:stretch-slim

# Set up the gcsfuse fuse module repo.
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-stretch main" > /etc/apt/sources.list.d/gcsfuse.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Update apt database and install necessary packages.
RUN apt-get update -qq
RUN apt-get install -qq curl fuse gcsfuse golang

RUN GOPATH=/root/go go get github.com/prometheus/snmp_exporter

VOLUME /etc/snmp_exporter
EXPOSE 9116

ENTRYPOINT /bin/snmp_exporter --config.file=/etc/snmp_exporter/snmp_exporter_config.yaml
