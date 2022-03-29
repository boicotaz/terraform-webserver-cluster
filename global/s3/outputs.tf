output "tf_state_s3_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "The name of the bucket that holds the terraform state."
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table, that hold the lock for the tf state"
}
