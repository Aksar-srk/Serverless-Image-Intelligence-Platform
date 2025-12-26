variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "photos_bucket_arn" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}
