output "photos_bucket_name" {
  value = aws_s3_bucket.photos.bucket
}

output "photos_bucket_arn" {
  value = aws_s3_bucket.photos.arn
}

output "web_bucket_name" {
  value = aws_s3_bucket.web.bucket
}

output "web_website_endpoint" {
  value = aws_s3_bucket_website_configuration.web.website_endpoint
}
