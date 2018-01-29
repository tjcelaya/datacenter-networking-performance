module "aws-us-west-2-vpc" {
  source = "aws-vpc"
  region = "us-west-2"
  availability_zones = {
    us-west-2a = ["10.10.10.0/24", "10.10.100.0/24"],
    us-west-2c = ["10.10.20.0/24", "10.10.200.0/24"]
  }
}

output "az_to_sub" {
  value = "${module.aws-us-west-2-vpc.az_to_subnet_id}"
}

module "aws-us-west-2a" {
  source = "aws"
  region = "us-west-2"
  ssh_user = "${var.aws_ssh_user}"
  instance_type = "${var.aws_instance_type}"
  ssh_key_path = "${var.aws_ssh_key_path}"
  availability_zone = "us-west-2a"
  vpc_id = "${module.aws-us-west-2-vpc.vpc_id}"
  sg_id = "${module.aws-us-west-2-vpc.sg_id}"
  private_subnet_id = "${module.aws-us-west-2-vpc.az_to_subnet_id["us-west-2a"]}"
}

output "aws-us-west-2a_server" {
  value = ["${module.aws-us-west-2a.server_ips}"]
}

output "aws-us-west-2a_client" {
  value = ["${module.aws-us-west-2a.client_ips}"]
}

module "aws-us-west-2c" {
  source = "aws"
  region = "us-west-2"
  ssh_user = "${var.aws_ssh_user}"
  instance_type = "${var.aws_instance_type}"
  ssh_key_path = "${var.aws_ssh_key_path}"
  availability_zone = "us-west-2c"
  vpc_id = "${module.aws-us-west-2-vpc.vpc_id}"
  sg_id = "${module.aws-us-west-2-vpc.sg_id}"
  private_subnet_id = "${module.aws-us-west-2-vpc.az_to_subnet_id["us-west-2c"]}"
}

output "aws-us-west-2c_server" {
  value = ["${module.aws-us-west-2c.server_ips}"]
}

output "aws-us-west-2c_client" {
  value = ["${module.aws-us-west-2c.client_ips}"]
}
