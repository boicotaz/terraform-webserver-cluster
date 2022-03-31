resource "aws_db_instance" "mysql" {
  identifier_prefix   = var.identifier_prefix
  engine              = "mysql"
  allocated_storage   = var.allocated_storage
  instance_class      = var.instance_class
  db_name             = "mysql_database"
  username            = "admin"
  password            = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["${var.secret_key_mysql_password}"]
  skip_final_snapshot = true
}

data "aws_secretsmanager_secret" "mysql" {
  arn = var.secret_manager_arn
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.mysql.id
}
