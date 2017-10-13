# prometheus-snmp-exporter

The Travis-CI deployment scripts in this repository expect a few things to be
true:

* You have created static public IPs with a known name in each of projects
  mlab-sandbox, mlab-staging and mlab-oti. The name applied to the static IP
  entities should be the same for all three projects, and then configured in the
  deploy\_snmp\_exporter.sh script in global variable `GCE_IP_NAME`.
* You have updated the firewall rules for the project and/or the GCE instance to
  allow inbound access to port 9116, as this is the port that snmp\_exporter
  listens on and it needs to be reachable by our Prometheus cluster.
* You have created a custom IAM Role in each project with at a minimum the following permissions:
  * compute.addresses.get
  * compute.addresses.use
  * compute.disks.create
  * compute.instances.create
  * compute.instances.delete
  * compute.instances.get
  * compute.instances.list
  * compute.instances.setMetadata
  * compute.networks.use
  * compute.networks.useExternalIp
  * compute.projects.get
  * compute.subnetworks.use
  * compute.subnetworks.useExternalIp
  * compute.zoneOperations.get
  * compute.zones.list
* You have created an IAM Service Account in each of the three projects,
  downloaded the JSON credentials for each, and then created a new IAM user with
  the custom role you created and the standard "Service Account User" roles.
  created to the service account.
