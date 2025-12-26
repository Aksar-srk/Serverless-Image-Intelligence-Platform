output "lambda_image_role_arn" {
  value = aws_iam_role.lambda_image_role.arn
}

output "lambda_search_role_arn" {
  value = aws_iam_role.lambda_search_role.arn
}
