terraform {
  required_version = ">= 0.10.3"
}

provider "aws" {
  region = "${var.region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "default" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2016.09*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["amazon"]
}

resource "aws_vpc" "main" {
  cidr_block                       = "192.168.0.0/16"
  assign_generated_ipv6_cidr_block = "true"

  tags {
    Name = "iperf-${var.region}"
  }
}

resource "aws_subnet" "public" {
  count                           = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                          = "${aws_vpc.main.id}"
  cidr_block                      = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)}"
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = {
    Name = "iperf-${element(data.aws_availability_zones.available.names, count.index)}-public"
  }
}

resource "aws_route_table" "public" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_security_group" "default" {
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmpv6"
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "server" {
  instance_type          = "${var.instance_type}"
  ami                    = "${data.aws_ami.default.id}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  ipv6_address_count     = "1"
  vpc_security_group_ids = ["${aws_security_group.default.id}", "${aws_vpc.main.default_security_group_id}"]

  tags = {
    Name = "iperf-server-${element(data.aws_availability_zones.available.names, count.index)}-${count.index}"
  }
}

