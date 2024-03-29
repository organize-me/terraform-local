resource "mysql_database" "home_portal" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name                  = "home_portal"
  depends_on            = [docker_container.mysql]
}

resource "mysql_user" "home_portal" {
  user               = "${data.aws_ssm_parameter.home_portal_db_username.value}"
  host               = "organize-me-home-portal.organize_me_network"
  plaintext_password = "${data.aws_ssm_parameter.home_portal_db_password.value}"
  depends_on         = [docker_container.mysql]
}

resource "mysql_grant" "home_portal" {
  user = "${mysql_user.home_portal.user}"
  host = "${mysql_user.home_portal.host}"
  database = "${mysql_database.home_portal.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.home_portal, mysql_database.home_portal]
}

resource "docker_image" "home_portal" {
  name         = "home-portal:latest"
  keep_locally = true
}

resource "docker_container" "home_portal" {
  image         = docker_image.home_portal.image_id
  name          = "organize-me-home-portal"
  hostname      = "home-portal"
  restart       = "unless-stopped"
  env   = [
    "TZ=${var.timezone}",
    "DATABASE_URL=jdbc:mysql://mysql:3306/home_portal?allowPublicKeyRetrieval=true&autoReconnect=true",
    "DATABASE_USERNAME=${data.aws_ssm_parameter.home_portal_db_username.value}",
    "DATABASE_PASSWORD=${data.aws_ssm_parameter.home_portal_db_password.value}",
    "OAUTH2_ENABLED=true",
    "OAUTH2_ADMIN=${data.aws_ssm_parameter.home_portal_admin_query.value}",
    "OAUTH2_ISSUER_URL=${data.aws_ssm_parameter.home_portal_issuer_url.value}",
    "OAUTH2_AUTH_URL=${data.aws_ssm_parameter.home_portal_auth_url.value}",
    "OAUTH2_TOKEN_URL=${data.aws_ssm_parameter.home_portal_token_url.value}",
    "OAUTH2_CLIENT_ID=${data.aws_ssm_parameter.home_portal_client_id.value}",
    "OAUTH2_CLIENT_SECRET=${data.aws_ssm_parameter.home_portal_client_secret.value}",
    "OAUTH2_CLIENT_SCOPE=${data.aws_ssm_parameter.home_portal_client_scope.value}"
  ]
    ports {
    internal = 8080
    external = 8099
  }
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["home-portal"]
    ipv4_address = "172.22.0.9"
  }
  depends_on = [mysql_grant.home_portal, mysql_user.home_portal, mysql_database.home_portal]
}
