variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "namespace_name" {
  description = "Redshift Serverless namespace name"
  type        = string
  default     = "analytics"
}

variable "workgroup_name" {
  description = "Redshift Serverless workgroup name"
  type        = string
  default     = "analytics"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "analytics"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}
