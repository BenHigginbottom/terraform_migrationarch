#Example 3-tier Architecture

This is the generic 3-tier architecture of Webserver - Appserver - Database platform with a few additions

* DynamoDB table created to act as a sessions datastore
* Autoscaling groups to allow for 'just enough' usage
* Multi-AZ for enhanced availability
* Logging (from the ELB's) into an S3 bucket

Most of the networking components have been pre-defined and are loaded into the variables file as opposed to being setup in the configuration to avoid any entertaining loops, likewise the security groups have been set to a very permissive model that would require hardeding if being used in anger

No internet gateway, as we are assuming we are connecting in via VPN

