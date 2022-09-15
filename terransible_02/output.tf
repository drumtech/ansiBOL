output "droplet_output" {
  value = digitalocean_droplet.tf_vm.*.ipv4_address
}
