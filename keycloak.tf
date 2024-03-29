resource "mysql_database" "keycloak" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name                  = "keycloak"
  depends_on            = [docker_container.mysql]
}

resource "mysql_user" "keycloak" {
  user               = "${data.aws_ssm_parameter.keycloak_db_username.value}"
  host               = "organize-me-keycloak.organize_me_network"
  plaintext_password = "${data.aws_ssm_parameter.keycloak_db_password.value}"
  depends_on         = [docker_container.mysql]
}

resource "mysql_grant" "keycloak" {
  user = "${mysql_user.keycloak.user}"
  host = "${mysql_user.keycloak.host}"
  database = "${mysql_database.keycloak.name}"
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.keycloak, mysql_database.keycloak]
}

resource "docker_image" "keycloak" {
  name         = "quay.io/keycloak/keycloak:22.0.5"
  keep_locally = true
}

resource "docker_container" "keycloak" {
  image         = docker_image.keycloak.image_id
  name          = "organize-me-keycloak"
  hostname      = "keycloak"
  restart       = "unless-stopped"
  command	= ["start-dev", "--http-relative-path", "/auth"]
  env   = [
    "TZ=${var.timezone}",
    #"KEYCLOAK_ADMIN=${data.aws_ssm_parameter.keycloak_username.value}",
    #"KEYCLOAK_ADMIN_PASSWORD=${data.aws_ssm_parameter.keycloak_password.value}",
    "KC_DB=mysql",
    "KC_DB_URL_HOST=mysql",
    "KC_DB_URL_PORT=3306",
    "KC_DB_URL_DATABASE=keycloak",
    "KC_DB_USERNAME=${data.aws_ssm_parameter.keycloak_db_username.value}",
    "KC_DB_PASSWORD=${data.aws_ssm_parameter.keycloak_db_password.value}",
    "KC_DB_URL_PROPERTIES=?connectTimeout=30",
    "KC_PROXY=edge"
  ]
  networks_advanced {
    name    = docker_network.organize_me_network.name
    aliases = ["keycloak"]
  }
  ports {
    internal = 8080
    external = 8080
  }
  depends_on = [mysql_grant.keycloak, mysql_user.keycloak, mysql_database.keycloak]
}
