variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_subnet" {
  type = list
  default =  ["eu-west-1a_snid", "eu-west-1b_snid"]
}

variable "identifier" {
  default     =  "benhdb-rds"
}

variable "storage" {
  default     = "10"
}

variable "engine" {
  default     = "mysql"
  description = "Not Oracle because $$$$$"
}

variable "engine_version" {
  description = "Engine version"

  default = {
    mysql    = "5.6.22"
    postgres = "9.4.1"
  }
}

variable "instance_class" {
  default     = "db.m4.large"
}

variable "db_name" {
  default     = "benhdb"
}

variable "username" {
  default     = "myuser"
}

variable "password" {
  default = "thisisreallysillytodoputtingapasswordintoaplaintextfile"
  description = "Probably better to provide it as an Envar"
}
