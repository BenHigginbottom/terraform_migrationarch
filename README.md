#Example 3-tier Architecture

This is the generic 3-tier architecture of Webserver - Appserver - Database platform with a few additions

* DynamoDB table created to act as a sessions datastore
* Autoscaling groups to allow for 'just enough' usage
* Multi-AZ for enhanced availability
* Logging (from the ELB's) into an S3 bucket

Most of the networking components have been pre-defined and are loaded into the variables file as opposed to being setup in the configuration to avoid any entertaining loops, likewise the security groups have been set to a very permissive model that would require hardeding if being used in anger

No internet gateway, as we are assuming we are connecting in via VPN

We will open with the standard provider and datasource to obtain our most current AMI, however because we are going to be using an Auto Scaling group, we first need a launch configuration. As we are going to be having 2 auto scaling groups, then we need to launch configurations.

Here we tell we want to use the normal AMI obtained from the datasource, and then the instance type, the webservers are unlikely to need the same resources as the app servers, so we go with a smaller instance type, we also pass in the user data information.

```bash
resource "aws_launch_configuration" "my_web_launch_config" {
    name          = "web_config"
    image_id      = "${data.aws_ami.list.id}"
    instance_type = "m3.medium"
    user_data     = "${file("webuserdata.sh")}"

}

resource "aws_launch_configuration" "my_app_launch_config" {
    name          = "app_config"
    image_id      = "${data.aws_ami.list.id}"
    instance_type = "m4.large"
    user_data     = "${file("appuserdata.sh")}"

}
```


Now we have the launch configurations, we define the autoscaling groups

```bash
resource "aws_asg" "my_web_asg" {
  availability_zones          = ["eu-west-1a", "eu-west-1b"]
  name                        = "my_autoscaling_webservers"
  max_size                    = 4
  min_size                    = 2
  health_check_grace_period   = 300
  health_check_type           = "ELB"
  desired_capacity            = 3
  loadbalancers               = ["${aws_elb.web.name}"]
  launch_configuration        = "${aws_launch_configuration.my_web_launch_config.name}"

  tag {
    key = "Terraformed"
    value = "True"
    propagate_at_launch = true
  }
}
```

This only shows one as they both resemble each other.

The first line states the availability zones we want to stretch the ASG across, in this case A&B of EU-WEST-1.

Min and Max sizes give us the ability to control the size of the ASG, mimimum 