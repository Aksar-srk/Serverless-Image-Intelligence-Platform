output "api_name" {
  description = "API Gateway REST API name"
  value       = aws_api_gateway_rest_api.api.name
}

output "api_invoke_url" {
  description = "Public HTTPS invoke URL for the API Gateway stage"
  value       = aws_api_gateway_stage.stage.invoke_url
}
