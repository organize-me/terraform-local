resource "mysql_database" "vaultwarden" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name                  = "vaultwarden"
  depends_on            = [docker_container.mysql]
}

resource "mysql_user" "vaultwarden" {
  user               = "${data.aws_ssm_parameter.vaultwarden_db_username.value}"
  host               = "organize-me-vaultwarden.organize_me_network"
  plaintext_password = "${data.aws_ssm_parameter.vaultwarden_db_password.value}"
  depends_on         = [docker_container.mysql]
}

resource "mysql_grant" "vaultwarden" {
  user = "${mysql_user.vaultwarden.user}"
  host = "${mysql_user.vaultwarden.host}"
  database = "${mysql_database.vaultwarden.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.vaultwarden, mysql_database.vaultwarden]
}

resource "docker_image" "vaultwarden" {
  name         = "vaultwarden/server:1.30.0"
  keep_locally = true
}

resource "docker_container" "vaultwarden" {
  image         = docker_image.vaultwarden.image_id
  name          = "organize-me-vaultwarden"
  hostname      = "vaultwarden"
  restart       = "unless-stopped"
  env   = [
      "TZ=${var.timezone}",
      "DOMAIN=https://vaultwarden.${var.domain}",
      "DATABASE_URL=mysql://${data.aws_ssm_parameter.vaultwarden_db_username.value}:${data.aws_ssm_parameter.vaultwarden_db_password.value}@mysql/vaultwarden",
      "LOGIN_RATELIMIT_MAX_BURST=10",
      "LOGIN_RATELIMIT_SECONDS=60",
      "ADMIN_RATELIMIT_MAX_BURST=10",
      "ADMIN_RATELIMIT_SECONDS=60",
      "ADMIN_TOKEN=${data.aws_ssm_parameter.vaultwarden_admin_token.value}",
      "SENDS_ALLOWED=true",
      "EMERGENCY_ACCESS_ALLOWED=false",
      "WEB_VAULT_ENABLED=true",
      "SIGNUPS_ALLOWED=false",
      "SIGNUPS_VERIFY=true",
      "SIGNUPS_VERIFY_RESEND_TIME=3600",
      "SIGNUPS_VERIFY_RESEND_LIMIT=5",
      "SIGNUPS_DOMAINS_WHITELIST=",
      "SMTP_HOST=${data.aws_ssm_parameter.smtp_host.value}",
      "SMTP_FROM=noreply@${var.domain}",
      "SMTP_FROM_NAME=noreply",
      "SMTP_SECURITY=starttls",
      "SMTP_PORT=${data.aws_ssm_parameter.smtp_port.value}",
      "SMTP_USERNAME=${data.aws_ssm_parameter.smtp_username.value}",
      "SMTP_PASSWORD=${data.aws_ssm_parameter.smtp_password.value}",
      "SMTP_AUTH_MECHANISM=Login"
  ]
  volumes {
    container_path = "/data/"
    host_path      = "${var.install_root}/vaultwarden/data/"
  }
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["vaultwarden"]
  }
  ports {
    internal = 80
    external = 8008
  }
  depends_on = [mysql_grant.vaultwarden, mysql_user.vaultwarden, mysql_database.vaultwarden]
}
