output "image_labeler_invoke_arn" {
  value = aws_lambda_function.image_labeler.invoke_arn
}

output "search_invoke_arn" {
  value = aws_lambda_function.search.invoke_arn
}

output "image_labeler_name" {
  value = aws_lambda_function.image_labeler.function_name
}

output "search_name" {
  value = aws_lambda_function.search.function_name
}
