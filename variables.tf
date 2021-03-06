variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_subnet_web" {
  default = ["subnet-d18f60b5", "subnet-0a85917d"]
}

variable "aws_subnet_app" {
  default = ["subnet-d18f60b5", "subnet-0a85917d"]
}

variable "aws_subnet_db" {
  default = ["subnet-d18f60b5", "subnet-0a85917d"]
}

variable "identifier" {
  default = "benhdb-rds"
}

variable "storage" {
  default = "10"
}

variable "engine" {
  default     = "mysql"
  description = "Not Oracle because $$$$$"
}

variable "instance_class" {
  default = "db.t2.large"
}

variable "dbkms" {
  default     = "foo"
  description = "ARN of KMS key for encrypting the database"
}

variable "db_name" {
  default = "benhdb"
}

variable "username" {
  default = "myuser"
}

variable "aws_snet_db" {
  default = "main"
}

variable "password" {
  default     = "thisisreallysillytodoputtingapasswordintoaplaintextfile"
  description = "Probably better to provide it as an Envar"
}
