# the vpc module doesn't allow passing these directly so just use
# the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY envs

provider "aws" {
  region = "${var.region}"
  # access_key = "${var.access_key}"
  # secret_key = "${var.secret_key}"
}

data "aws_iam_user" "default" {
  user_name = "${var.ssh_user}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_vpc" "selected" {
  id = "${var.vpc_id}"
}

resource "aws_instance" "iperf_server" {
  tags {
    Name = "i-${var.availability_zone}-iperf-server"
  }

  subnet_id = "${var.private_subnet_id}"
  vpc_security_group_ids = ["${var.sg_id}"]
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  count = 1
  availability_zone = "${var.availability_zone}"

  key_name = "tjcelaya-tf-aws-rsa"

  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${self.public_ip}"
    private_key = "${file(var.ssh_key_path)}"
  }



  provisioner "file" {
    source = "conf/iperf3.service"
    destination = "/tmp/iperf3.service"
  }
  provisioner "remote-exec" {
    inline = [
    "sudo mv /tmp/iperf3.service /etc/systemd/system/iperf3.service",
    "sudo apt-get update",
    "sudo apt-get install -y iperf3",
    "sudo systemctl daemon-reload",
    "sudo systemctl enable iperf3",
    "sudo systemctl start iperf3",
    ]
  }
}

resource "aws_instance" "iperf_client" {
  tags {
    Name = "i-${var.availability_zone}-iperf-client"
  }

  subnet_id = "${var.private_subnet_id}"
  vpc_security_group_ids = ["${var.sg_id}"]
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  count = 1
  availability_zone = "${var.availability_zone}"

  key_name = "tjcelaya-tf-aws-rsa"

  connection {
    type = "ssh"
    user = "ubuntu"
    host = "${self.public_ip}"
    private_key = "${file(var.ssh_key_path)}"
  }

  provisioner "file" {
    source = "conf/terse_iperf_client.sh"
    destination = "/tmp/terse_iperf_client.sh"
  }
  provisioner "remote-exec" {
    inline = [
    "sudo mv /tmp/terse_iperf_client.sh /usr/local/bin/terse_iperf_client.sh",
    "sudo chmod +x /usr/local/bin/terse_iperf_client.sh",
    "sudo apt-get update",
    "sudo apt-get install -y iperf3",
    ] 
  }
}
