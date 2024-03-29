resource "mysql_database" "nextcloud" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name                  = "nextcloud"
  depends_on            = [docker_container.mysql]
}

resource "mysql_user" "nextcloud" {
  user               = "${data.aws_ssm_parameter.nextcloud_db_username.value}"
  host               = "organize-me-nextcloud.organize_me_network"
  plaintext_password = "${data.aws_ssm_parameter.nextcloud_db_password.value}"
  depends_on         = [docker_container.mysql]
}

resource "mysql_grant" "nextcloud" {
  user = "${mysql_user.nextcloud.user}"
  host = "${mysql_user.nextcloud.host}"
  database = "${mysql_database.nextcloud.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.nextcloud, mysql_database.nextcloud]
}

resource "docker_image" "nextcloud" {
  name         = "nextcloud:27.1.3-apache"
  keep_locally = true
}

resource "docker_container" "nextcloud" {
  image         = docker_image.nextcloud.image_id
  name          = "organize-me-nextcloud"
  hostname      = "nextcloud"
  restart       = "unless-stopped"
  env   = [
    "TZ=${var.timezone}",
    "MYSQL_HOST=mysql",
    "DB_PORT=3306",
    "MYSQL_USER=${data.aws_ssm_parameter.nextcloud_db_username.value}",
    "MYSQL_PASSWORD=${data.aws_ssm_parameter.nextcloud_db_password.value}",
    "MYSQL_DATABASE=nextcloud",
    "OVERWRITEPROTOCOL=https",
    "NEXTCLOUD_ADMIN_USER=${data.aws_ssm_parameter.nextcloud_username.value}",
    "NEXTCLOUD_ADMIN_PASSWORD=${data.aws_ssm_parameter.nextcloud_password.value}",
    "NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.${var.domain}",
    "SMTP_HOST=${data.aws_ssm_parameter.smtp_host.value}",
    "SMTP_SECURE=tls",
    "SMTP_PORT=${data.aws_ssm_parameter.smtp_port.value}",
    "SMTP_NAME=${data.aws_ssm_parameter.smtp_username.value}",
    "SMTP_PASSWORD=${data.aws_ssm_parameter.smtp_password.value}",
    "MAIL_FROM_ADDRESS=noreplay",
    "MAIL_DOMAIN=${var.domain}"
  ]
  volumes {
    container_path = "/var/www/html/"
    host_path      = "${var.install_root}/nextcloud/var/www/html"
  }
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["nextcloud"]
  }
  ports {
    internal = 80
    external = 8000
  }
  depends_on = [mysql_grant.nextcloud, mysql_user.nextcloud, mysql_database.nextcloud]
}
