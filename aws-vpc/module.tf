provider "aws" {
  region = "${var.region}"
  # access_key = "${var.access_key}"
  # secret_key = "${var.secret_key}"
}

variable "region" {
  default = "us-west-2"
}

variable "cidr_block" {
  description = "The CDIR block used for the VPC."
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  type = "map"
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_block}"

  tags {
    Name = "${var.region}-iperf-vpc"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.region}-iperf-internet-gateway"
  }
}

resource "aws_route_table" "public_routetable" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internet_gateway.id}"
  }

  tags {
    Name = "${var.region}-iperf-public-routetable"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(keys(var.availability_zones))}"
  availability_zone       = "${element(keys(var.availability_zones), count.index)}"
  cidr_block              = "${element(var.availability_zones[element(keys(var.availability_zones), count.index)], 0)}"
  map_public_ip_on_launch = true

  tags {
    Name        = "${element(keys(var.availability_zones), count.index)}-iperf-public-subnet"
  }
}

resource "aws_route_table_association" "public_routing_table" {
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_routetable.id}"
  count          = "${length(keys(var.availability_zones))}"
}

resource "aws_route_table" "private_routetable" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }

  tags {
    Name        = "${var.region}-iperf-private-routetable"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  count                   = "${length(keys(var.availability_zones))}"
  availability_zone       = "${element(keys(var.availability_zones), count.index)}"
  cidr_block              = "${element(var.availability_zones[element(keys(var.availability_zones), count.index)], 1)}"
  map_public_ip_on_launch = true

  tags {
    Name        = "${element(keys(var.availability_zones), count.index)}-iperf-private-subnet"
  }
}

resource "aws_route_table_association" "private_routing_table" {
  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private_routetable.id}"
  count          = "${length(keys(var.availability_zones))}"
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = "${aws_vpc.vpc.id}"
  route_table_id = "${aws_route_table.private_routetable.id}"
}

resource "aws_network_acl" "main" {
  vpc_id = "${aws_vpc.vpc.id}"

  # TODO: make this less ridiculous
  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "${var.cidr_block}"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${var.cidr_block}"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name = "${var.region}-iperf-network-acl"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_subnet.0.id}"
}

output "sg_id" {
  value = "${aws_security_group.allow_all.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "az_to_subnet_id" {
  value = "${zipmap(
    aws_subnet.private_subnet.*.availability_zone, aws_subnet.private_subnet.*.id
    )}"
}