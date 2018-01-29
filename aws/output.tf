output "server_ips" {
    value = [
      "${aws_instance.iperf_server.*.public_ip}",
      "${aws_instance.iperf_server.*.private_ip}"
    ]
}

output "client_ips" {
    value = [
      "${aws_instance.iperf_client.*.public_ip}",
      "${aws_instance.iperf_client.*.private_ip}"
    ]
}
