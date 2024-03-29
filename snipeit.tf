resource "mysql_database" "snipeit" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name                  = "snipeit"
  depends_on            = [docker_container.mysql]
}

resource "mysql_user" "snipeit" {
  user               = "${data.aws_ssm_parameter.snipeit_db_username.value}"
  host               = "organize-me-snipeit.organize_me_network"
  plaintext_password = "${data.aws_ssm_parameter.snipeit_db_password.value}"
  depends_on         = [docker_container.mysql]
}

resource "mysql_grant" "snipeit" {
  user = "${mysql_user.snipeit.user}"
  host = "${mysql_user.snipeit.host}"
  database = "${mysql_database.snipeit.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.snipeit, mysql_database.snipeit]
}

resource "docker_image" "snipeit" {
  name         = "snipe/snipe-it:v6.2.3"
  keep_locally = true
}

resource "docker_container" "snipeit" {
  image         = docker_image.snipeit.image_id
  name          = "organize-me-snipeit"
  hostname      = "snipeit"
  restart       = "unless-stopped"
  env   = [
    "TZ=${var.timezone}",
    "MYSQL_PORT_3306_TCP_ADDR=mysql",
    "MYSQL_PORT_3306_TCP_PORT=3306",
    "MYSQL_DATABASE=snipeit",
    "MYSQL_USER=${data.aws_ssm_parameter.snipeit_db_username.value}",
    "MYSQL_PASSWORD=${data.aws_ssm_parameter.snipeit_db_password.value}",
    "MAIL_PORT_587_TCP_ADDR=${data.aws_ssm_parameter.smtp_host.value}",
    "MAIL_PORT_587_TCP_PORT=${data.aws_ssm_parameter.smtp_port.value}",
    "MAIL_ENV_FROM_ADDR=noreply@${var.domain}",
    "MAIL_ENV_FROM_NAME=Snipe-IT",
    "MAIL_ENV_ENCRYPTION=tls",
    "MAIL_ENV_USERNAME=${data.aws_ssm_parameter.smtp_username.value}",
    "MAIL_ENV_PASSWORD=${data.aws_ssm_parameter.smtp_password.value}",
    "APP_ENV=production",
    "APP_DEBUG=false",
    "APP_KEY=${data.aws_ssm_parameter.snipeit_appkey.value}",
    "APP_URL=https://snipeit.${var.domain}",
    "APP_TRUSTED_PROXIES=172.22.0.0/16",
    "APP_TIMEZONE=${var.timezone}",
    "APP_LOCALE=en"
  ]
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["snipeit"]
  }
  ports {
    internal = 80
    external = 6002
  }
  depends_on = [mysql_grant.snipeit, mysql_user.snipeit, mysql_database.snipeit]
}
