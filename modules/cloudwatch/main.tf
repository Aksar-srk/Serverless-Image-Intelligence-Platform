#################################
# CloudWatch Log Groups for Lambdas
#################################

resource "aws_cloudwatch_log_group" "image_lambda" {
  name              = "/aws/lambda/${var.image_labeler_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Component = "logs-lambda-image"
  })
}

resource "aws_cloudwatch_log_group" "search_lambda" {
  name              = "/aws/lambda/${var.search_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Component = "logs-lambda-search"
  })
}

#################################
# CloudWatch Log Group for API Gateway
#################################

resource "aws_cloudwatch_log_group" "api_gw_log" {
  name              = "/aws/apigateway/${var.api_gateway_name}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Component = "logs-apigw"
  })
}
