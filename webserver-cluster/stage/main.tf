provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-state-425832464758"
    key    = "webserver-cluster/stage/terraform.tfstate"
    region = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

module "mysql_database" {
  source                    = "../../modules/data-stores/mysql"
  identifier_prefix         = "webserver-cluster-mysql"
  secret_manager_arn        = "arn:aws:secretsmanager:us-east-2:425832464758:secret:stage/mysql-chDb1V"
  secret_key_mysql_password = "mysql-master-password-stage"
  instance_class            = "db.t2.micro"
  allocated_storage         = "10"
}

module "webserver_cluster" {
  source        = "../../modules/services/webserver-cluster"
  cluster_name  = "webserver-cluster"
  db_address    = module.mysql_database.address
  db_port       = module.mysql_database.port
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}
