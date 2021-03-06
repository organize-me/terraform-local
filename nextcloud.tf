resource "mysql_database" "nextcloud" {
  default_character_set = "utf8mb3"
  name                  = "nextcloud"
  depends_on = [docker_container.mysql]
}

resource "mysql_user" "nextcloud" {
  user               = "${data.aws_ssm_parameter.nextcloud_db_username.value}"
  host               = "172.22.0.5"
  plaintext_password = "${data.aws_ssm_parameter.nextcloud_db_password.value}"
  depends_on = [docker_container.mysql]
}

resource "mysql_grant" "nextcloud" {
  user = "${mysql_user.nextcloud.user}"
  host = "${mysql_user.nextcloud.host}"
  database = "${mysql_database.nextcloud.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.nextcloud, mysql_database.nextcloud]
}

resource "docker_image" "nextcloud" {
  name         = "nextcloud:24.0-apache"
  keep_locally = true
}

resource "docker_container" "nextcloud" {
  image         = docker_image.nextcloud.latest
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
    "OBJECTSTORE_S3_BUCKET=nextcloud.${var.domain}",
    "OBJECTSTORE_S3_KEY=${data.aws_ssm_parameter.nextcloud_access_key.value}",
    "OBJECTSTORE_S3_SECRET=${data.aws_ssm_parameter.nextcloud_secret_access_key.value}",
    "OBJECTSTORE_S3_REGION=${data.aws_ssm_parameter.nextcloud_region.value}",
    "OBJECTSTORE_S3_AUTOCREATE=false",
    "SMTP_HOST=${data.aws_ssm_parameter.smtp_host.value}",
    "SMTP_SECURE=tls",
    "SMTP_PORT=${data.aws_ssm_parameter.smtp_port.value}",
    "SMTP_NAME=${data.aws_ssm_parameter.smtp_username.value}",
    "SMTP_PASSWORD=${data.aws_ssm_parameter.smtp_password.value}",
    "MAIL_FROM_ADDRESS=noreplay",
    "MAIL_DOMAIN=${var.domain}"
  ]
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["nextcloud"]
    ipv4_address = "172.22.0.5"
  }
  ports {
    internal = 80
    external = 8000
  }
  depends_on = [mysql_grant.nextcloud, mysql_user.nextcloud, mysql_database.nextcloud]
}
