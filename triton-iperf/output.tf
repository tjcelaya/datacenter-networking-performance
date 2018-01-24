output "server_ips" {
    value = ["${triton_machine.iperf_server.ips}"]
}

output "client_ips" {
    value = ["${triton_machine.iperf_client.ips}"]
}
