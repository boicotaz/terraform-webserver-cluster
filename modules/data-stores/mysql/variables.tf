# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "identifier_prefix" {
  description = "The identifier prefix for this instance of RDS"
  type        = string
}

variable "secret_manager_arn" {
  description = "The secret manager arn that contains the mysql master password."
  type        = string
}

variable "secret_key_mysql_password" {
  description = "The key for the mysql master password, located aws secrets manager."
  type        = string
}

variable "instance_class" {
  description = "The RDS instance class."
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in gibibytes"
  type        = number
}
