variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "aws_region" {
  type = string
}

variable "lambda_memory_mb" {
  type = number
}

variable "lambda_timeout_seconds" {
  type = number
}

variable "photos_bucket_name" {
  type = string
}

variable "photos_bucket_arn" {
  type = string
}

variable "table_name" {
  type = string
}

variable "lambda_image_role_arn" {
  type = string
}

variable "lambda_search_role_arn" {
  type = string
}
