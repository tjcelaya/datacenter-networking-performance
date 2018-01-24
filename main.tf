module "triton-us-east-1a" {
  source = "triton-iperf"
  region = "us-east-1a"
}

output "us-east-1a_server" {
  value = ["${module.triton-us-east-1a.server_ips}"]
}

output "us-east-1a_client" {
  value = ["${module.triton-us-east-1a.client_ips}"]
}

# output "us-east-1a-iperf_client_ips" {
#   value = ["${module.triton-us-east-1a-client.ips}"]
# }