provider "aws" {
  region = "us-east-2"
}
terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-state-425832464758"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  db_name           = "example_database"
  username          = "admin"
  password          = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["mysql-master-password-stage"]
}

data "aws_secretsmanager_secret" "mysql" {
  arn = "arn:aws:secretsmanager:us-east-2:425832464758:secret:stage/mysql-chDb1V"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.mysql.id
}
