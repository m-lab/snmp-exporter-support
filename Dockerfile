FROM prom/snmp-exporter:v0.6.0
MAINTAINER support@measurementlab.net
ADD mlab.yml /etc/snmp_exporter/snmp.yml
