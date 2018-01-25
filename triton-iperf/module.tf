terraform {
  required_version = ">= 0.10.0"
}

provider "triton" {
  url = "https://${var.region}.api.${var.base_url}"
  account = "${var.account}"
  key_id = "${var.key_id}"
}

data "triton_network" "public" {
    name = "Joyent-SDC-Public"
}

data "triton_network" "private" {
    name = "${var.private_network_name}"
}

data "triton_image" "ubuntu" {
    name = "ubuntu-16.04"
    version = "20170403"
}

resource "triton_machine" "iperf_server" {
    name = "iperf-server-tf"
    package = "g4-highcpu-64G"
    image   = "${data.triton_image.ubuntu.id}"
    networks = 
    [
      "${data.triton_network.public.id}",
      "${data.triton_network.private.id}"
    ]

    provisioner "file" {
      source = "conf/iperf3.service"
      destination = "/etc/systemd/system/iperf3.service"
    }
    provisioner "remote-exec" {
      inline = [
        "apt-get update -qq",
        "apt-get install -qq -y iperf3",
        "systemctl daemon-reload",
        "systemctl enable iperf3",
        "systemctl start iperf3",
      ]
    }
}

resource "triton_machine" "iperf_client" {
    name = "iperf-client-tf"
    package = "g4-highcpu-1G"
    image   = "${data.triton_image.ubuntu.id}"
    networks = 
    [
      "${data.triton_network.public.id}",
      "${data.triton_network.private.id}"
    ]

    provisioner "file" {
      source = "conf/terse_iperf_client.sh"
      destination = "/usr/local/bin/terse_iperf_client.sh"
    }
    provisioner "remote-exec" {
      inline = [
        "chmod +x /usr/local/bin/terse_iperf_client.sh",
        "apt-get update -qq",
        "apt-get install -qq -y iperf3"
      ]
    }
}

