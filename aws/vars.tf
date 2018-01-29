variable "region" {}

variable "instance_type" {
  default = "t2.nano"
}

variable "ssh_user" {}

variable "ssh_key_path" {}

variable "availability_zone" {}

variable "vpc_id" {}

variable "private_subnet_id" {}

variable "sg_id" {}

