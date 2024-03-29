resource "docker_image" "pihole" {
  name = "pihole/pihole:2023.10.0"
  keep_locally = true
}

resource "docker_container" "pihole" {
  image    = docker_image.pihole.image_id
  name     = "organize-me-pihole"
  hostname = "pihole"
  restart  = "unless-stopped"
  env = [
    "TZ=${var.timezone}"
  ]
  volumes {
    container_path = "/etc/pihole"
    host_path      = "${var.install_root}/pihole/etc/pihole"
  }
  volumes {
    container_path = "/etc/dnsmasq.d"
    host_path      = "${var.install_root}/pihole/etc/dnsmasq.d"
  }
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["pihole"]
  }
  ports {
    internal = 53
    external = 53
    protocol = "tcp"
  }
  ports {
    internal = 53
    external = 53
    protocol = "udp"
  }
  ports {
    internal = 67
    external = 67
    protocol = "udp"
  }
  capabilities {
    add = ["NET_ADMIN"]
  }
}
