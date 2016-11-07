#Being built with TF0.7.9

provider "aws" {
  region                   = "${var.aws_region}"
  shared_credentials_file  = "/home/ben/.aws/pers"
}


data "aws_ami" "list" {
  most_recent = true
  filter {
    name = "tag:Author"
    values = ["Ben"]
  }
  filter {
    name = "tag:OS"
    values = ["Amazon"]
  }
  filter {
    name = "tag:Version"
    values = ["6"]
  }
}


resource "aws_launch_configuration" "my_web_launch_config" {
    name = "web_config"
    image_id = "${data.aws_ami.list.id}"
    instance_type = "m3.medium"
}

resource "aws_launch_configuration" "my_app_launch_config" {
    name = "app_config"
    image_id = "${data.aws_ami.list.id}"
    instance_type = "m4.large"
}


resource "aws_asg" "my_web_asg" {
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  name = "my_autoscaling_application"
  max_size = 4
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 3
  loadbalancers = ["${aws_elb.web.name}"]
  launch_configuration = "${aws_launch_configuration.my_web_launch_config.name}"

  tag {
    key = "Terraformed"
    value = "True"
    propagate_at_launch = true
  }
}

resource "aws_asg" "my_app_asg" {
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  name = "my_autoscaling_application"
  max_size = 4
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 3
  loadbalancers = ["${aws_elb.app.name}"]
  launch_configuration = "${aws_launch_configuration.my_app_launch_config.name}"

  tag {
    key = "Terraformed"
    value = "True"
    propagate_at_launch = true
  }
}

resource "aws_s3_bucket" "bucket" {
    bucket = "benh_elb_logging_bucket"
    acl = "private"

    tags {
        Name = "Function"
        Environment = "ELB Logging Bucket"
    }
}

resource "aws_elb" "web" {
  name = "terraform-web-elb"

  subnets = ["${var.aws_subnet_web}"]

  access_logs {
    bucket = "benh_elb_logging_bucket"
    bucket_prefix = "web"
    interval = 60
  }


  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }
}

resource "aws_elb" "app" {
  name = "terraform-app-elb"

  subnets = ["${var.aws_subnet_app}"]

  access_logs {
    bucket = "benh_elb_logging_bucket"
    bucket_prefix = "app"
    interval = 60
  }


  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

}

resource "aws_db_instance" "development" {
  identifier             = "${var.identifier}"
  allocated_storage      = "${var.storage}"
  engine                 = "${var.engine}"
  instance_class         = "${var.instance_class}"
  name                   = "${var.db_name}"
  username               = "${var.username}"
  password               = "${var.password}"
}

resource "aws_dynamodb_table" "sessions-dynamodb-table" {
  name = "Sessions"
  read_capacity = 20
  write_capacity = 20
  hash_key = "UserId"
  attribute {
    name = "UserId"
    type = "S"
  }
  attribute {
    name = "session"
    type = "b"
  }
}

output "Web DNS Name" {
  value = "${aws_elb.web.name}"
}

output "AppServer DNS Name" {
  value = "${aws_elb.app.name}"
}