provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-state-425832464758"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

module "webserver_cluster" {
  source                 = "../../../modules/services/webserver-cluster"
  cluster_name           = "webserver-cluster"
  db_remote_state_bucket = "terraform-state-425832464758"
  db_remote_state_key    = "stage/data-stores/mysql/terraform.tfstate"
  db_remote_state_region = "us-east-2"
  instance_type          = "t2.micro"
  min_size               = 2
  max_size               = 2
}
