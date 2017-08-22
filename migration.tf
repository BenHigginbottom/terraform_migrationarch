#Being built with TF0.7.9

provider "aws" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "/home/ben/.aws/pers"
}

data "aws_ami" "list" {
  most_recent = true

  filter {
    name   = "tag:Author"
    values = ["Ben"]
  }

  filter {
    name   = "tag:OS"
    values = ["Amazon"]
  }

  filter {
    name   = "tag:Version"
    values = ["6"]
  }
}

resource "aws_launch_configuration" "my_web_launch_config" {
  name          = "web_config"
  image_id      = "${data.aws_ami.list.id}"
  instance_type = "t2.micro"
  user_data     = "${file("webuserdata.sh")}"
}

resource "aws_launch_configuration" "my_app_launch_config" {
  name          = "app_config"
  image_id      = "${data.aws_ami.list.id}"
  instance_type = "t2.micro"
  user_data     = "${file("appuserdata.sh")}"
}

resource "aws_autoscaling_group" "my_web_asg" {
  availability_zones        = ["eu-west-1a", "eu-west-1b"]
  name                      = "my_autoscaling_webservers"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 3
  load_balancers            = ["${aws_elb.web.name}"]
  launch_configuration      = "${aws_launch_configuration.my_web_launch_config.name}"

  tag {
    key                 = "Terraformed"
    value               = "True"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "my_app_asg" {
  availability_zones        = ["eu-west-1a", "eu-west-1b"]
  name                      = "my_autoscaling_appservers"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 3
  load_balancers            = ["${aws_elb.app.name}"]
  launch_configuration      = "${aws_launch_configuration.my_app_launch_config.name}"

  tag {
    key                 = "Terraformed"
    value               = "True"
    propagate_at_launch = true
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "benhelbloggingbucket081116"
  acl    = "private"

  tags {
    Name        = "Function"
    Environment = "ELB Logging Bucket"
  }
}

resource "aws_elb" "web" {
  name = "terraform-web-elb"

  subnets = ["${var.aws_subnet_web}"]

  access_logs {
    bucket        = "benhelbloggingbucket081116"
    bucket_prefix = "web"
    interval      = 60
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

resource "aws_elb" "app" {
  name = "terraform-app-elb"

  subnets = ["${var.aws_subnet_app}"]

  access_logs {
    bucket        = "benhelbloggingbucket081116"
    bucket_prefix = "app"
    interval      = 60
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = ["${var.aws_snet_db}"]

  tags {
    Terraformed = "True"
  }
}

resource "aws_db_instance" "development" {
  identifier                 = "${var.identifier}"
  allocated_storage          = "${var.storage}"
  storage_type               = "gp2"
  engine                     = "${var.engine}"
  instance_class             = "${var.instance_class}"
  name                       = "${var.db_name}"
  username                   = "${var.username}"
  password                   = "${var.password}"
  storage_encrypted          = "true"
  maintenance_window         = "SUN:00:00-SUN:03:00"
  auto_minor_version_upgrade = "true"
  multi_az                   = "true"
  backup_window              = "03:30-04:00"
  backup_retention_period    = "30"
  kms_key_id                 = "${var.dbkms}"
  db_subnet_group_name       = "${aws_db_subnet_group.default.id}"
}

resource "aws_dynamodb_table" "sessions-dynamodb-table" {
  name           = "Sessions"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "session"
    type = "B"
  }
}

output "Web DNS Name" {
  value = "${aws_elb.web.name}"
}

output "AppServer DNS Name" {
  value = "${aws_elb.app.name}"
}

output "Database Address" {
  value = "${aws_db_instance.development.address}"
}
