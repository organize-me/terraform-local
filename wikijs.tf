resource "mysql_database" "wikijs" {
  default_character_set = "utf8mb3"
  name                  = "wikijs"
  depends_on = [docker_container.mysql]
}

resource "mysql_user" "wikijs" {
  user               = "${data.aws_ssm_parameter.wikijs_db_username.value}"
  host               = "172.22.0.4"
  plaintext_password = "${data.aws_ssm_parameter.wikijs_db_password.value}"
  depends_on = [docker_container.mysql]
}

resource "mysql_grant" "wikijs" {
  user = "${mysql_user.wikijs.user}"
  host = "${mysql_user.wikijs.host}"
  database = "${mysql_database.wikijs.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.wikijs, mysql_database.wikijs]
}

resource "docker_image" "wikijs" {
  name         = "ghcr.io/requarks/wiki:2"
  keep_locally = true
}

resource "docker_container" "wikijs" {
  image         = docker_image.wikijs.latest
  name          = "organize-me-wikijs"
  hostname      = "wikijs"
  restart       = "unless-stopped"
  env   = [
    "TZ=${var.timezone}",
    "DB_TYPE=mysql",
    "DB_HOST=mysql",
    "DB_PORT=3306",
    "DB_USER=${data.aws_ssm_parameter.wikijs_db_username.value}",
    "DB_PASS=${data.aws_ssm_parameter.wikijs_db_password.value}",
    "DB_NAME=wikijs"
  ]
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["wikijs"]
    ipv4_address = "172.22.0.4"
  }
  ports {
    internal = 3000
    external = 3000
  }
  depends_on = [mysql_grant.wikijs, mysql_user.wikijs, mysql_database.wikijs]
}
