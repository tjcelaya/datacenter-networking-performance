variable "region" {}

variable "base_url" {
  default = "joyent.com"
}

variable "account" {
}

variable "private_network_name" {
  default = "Joyent-SDC-Private"
}

variable "key_id" {
}

variable "package" {
  default = "g4-highcpu-64G"
}

variable "image_name" {
  default = "ubuntu-16.04"
}

variable "image_version" {
  default = "20170403"
}
