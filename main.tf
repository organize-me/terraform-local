terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 3.0.1"
    }
    mysql = {
      source  = "bangau1/mysql"
      version = "= 1.10.4"
    }
  }
}

provider "docker" {
}

resource "docker_network" "organize_me_network" {
  name   = "organize_me_network"
  driver = "bridge"

  ipam_config {
    aux_address = {}
    gateway     = "172.22.0.1"
    subnet      = "172.22.0.0/16"
  }
}
