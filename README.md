# prometheus-snmp-exporter

The Travis-CI deployment scripts in this repository expect a few things to be
true:

* You have a created a GCE instance to host the snmp\_exporter.
* You have [installed Docker on the GCE instance](
  https://docs.docker.com/engine/installation/linux/docker-ce/debian/#install-using-the-repository).
* You have updated the firewall rules for the project and/or GCE instance to
  allow inbound access to port 9116.
* You have updated the variables at the head of `deploy_snmp_exporter.sh` with
  values appropriate to the GCE instance you created.
