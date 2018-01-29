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

data "triton_image" "base_image" {
    name = "${var.image_name}"
    version = "${var.image_version}"
}

resource "triton_machine" "iperf_server" {
    name = "iperf-${var.region}-server-tf"
    package = "${var.package}"
    image   = "${data.triton_image.base_image.id}"
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
        "apt-get install -yqq iperf3",
        "systemctl daemon-reload",
        "systemctl enable iperf3",
        "systemctl start iperf3",
      ]
    }
}

resource "triton_machine" "iperf_client" {
    name = "iperf-${var.region}-client-tf"
    package = "${var.package}"
    image   = "${data.triton_image.base_image.id}"
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
        "apt-get install -yqq iperf3",
      ]
    }
}

