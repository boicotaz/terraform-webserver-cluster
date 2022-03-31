output "address" {
  value       = aws_db_instance.mysql.address
  description = "The address for the mysql database"
}

output "port" {
  value       = aws_db_instance.mysql.port
  description = "The port used for connecting to the mysql database"
}
