output "photos_bucket_name" {
  description = "S3 bucket where photos should be uploaded (images/ prefix)"
  value       = module.s3.photos_bucket_name
}

output "web_bucket_name" {
  description = "S3 bucket for static website hosting"
  value       = module.s3.web_bucket_name
}

output "web_website_endpoint" {
  description = "S3 static website URL"
  value       = module.s3.web_website_endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB table storing image metadata"
  value       = module.dynamodb.table_name
}

output "api_invoke_url" {
  description = "Invoke URL for the search API (GET /search?tag=flower)"
  value       = module.apigateway.api_invoke_url
}
