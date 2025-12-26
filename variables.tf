variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Base project name used for resource naming"
  default     = "visual-wizard"
}

variable "api_stage_name" {
  type        = string
  description = "API Gateway stage name"
  default     = "prod"
}

variable "lambda_memory_mb" {
  type        = number
  description = "Lambda memory size in MB"
  default     = 256
}

variable "lambda_timeout_seconds" {
  type        = number
  description = "Lambda timeout in seconds"
  default     = 30
}