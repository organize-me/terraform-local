provider "mysql" {
  endpoint = "localhost:3306"
  username = "root"
  password = data.aws_ssm_parameter.mysql_password.value
}

resource "docker_image" "mysql" {
  name         = "ivcode/mysql:8.2-SNAPSHOT"
  keep_locally = true
}

resource "docker_container" "mysql" {
  image        = docker_image.mysql.image_id
  name         = "organize-me-mysql"
  hostname     = "mysql"
  restart      = "unless-stopped"
  wait         = true
  wait_timeout = 90

  env   = [
    "MYSQL_ROOT_PASSWORD=${data.aws_ssm_parameter.mysql_password.value}"
  ]
  volumes {
    container_path = "/var/lib/mysql"
    host_path      = "${var.install_root}/mysql/var/lib/mysql"
  }
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["mysql"]
  }
  ports {
    internal = 3306
    external = 3306
  }
}
