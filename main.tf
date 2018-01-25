module "triton-us-east-1a" {
  source = "triton-iperf"
  region = "us-east-1a"
}

module "triton-us-east-1b" {
  source = "triton-iperf"
  region = "us-east-1b"
}

module "triton-us-east-1c" {
  source = "triton-iperf"
  region = "us-east-1c"
}

output "us-east-1a_server" {
  value = ["${module.triton-us-east-1a.server_ips}"]
}

output "us-east-1a_client" {
  value = ["${module.triton-us-east-1a.client_ips}"]
}

output "us-east-1b_server" {
  value = ["${module.triton-us-east-1b.server_ips}"]
}

output "us-east-1b_client" {
  value = ["${module.triton-us-east-1b.client_ips}"]
}

output "us-east-1c_server" {
  value = ["${module.triton-us-east-1c.server_ips}"]
}

output "us-east-1c_client" {
  value = ["${module.triton-us-east-1c.client_ips}"]
}

