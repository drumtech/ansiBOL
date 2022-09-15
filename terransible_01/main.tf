terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "my_key" {
  name       = "kuptsov_pub_key"
  public_key = file(var.ssh_key)
}

data "digitalocean_ssh_key" "admin_key" {
  name = "REBRAIN.SSH.PUB.KEY"
}

resource "digitalocean_droplet" "tf_vm" {
  name                 = "tf-vm-02"
  image                = "centos-7-x64"
  size                 = "s-1vcpu-1gb"
  region               = "fra1"
  ssh_keys             = [digitalocean_ssh_key.my_key.fingerprint, data.digitalocean_ssh_key.admin_key.fingerprint]
  tags                 = [digitalocean_tag.my_tag.name, digitalocean_tag.my_email.name]
  provisioner "remote-exec" {
    inline = ["sudo yum install epel-release -y", "echo Done!"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.ssh_private)
    }
  }
}

resource "digitalocean_tag" "my_tag" {
  name = "devops"
}

resource "digitalocean_tag" "my_email" {
  name = var.email
}
resource "local_file" "inventory" {
  content = join("", data.template_file.inventory_file[*].rendered)
  filename = "${path.module}/hosts.yaml"
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts.yaml  nginx.yaml"
  }
}

data "template_file" "inventory_file" {
  template = "${file("${path.module}/hosts.tftpl")}"
  vars = {
    ip_addr = digitalocean_droplet.tf_vm.ipv4_address
    user = "root"
    path_to_key = "~/.ssh/rebrain"
  }
}
