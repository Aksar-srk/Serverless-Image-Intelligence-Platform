#################################
# API Gateway - REST API for search
#################################

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.name_prefix}-api"
  description = "Visual Wizard image search API"
}

# /search resource
resource "aws_api_gateway_resource" "search" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "search"
}

# GET /search?tag=<value>
resource "aws_api_gateway_method" "search_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.search.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.tag" = true
  }
}

# Lambda proxy integration
resource "aws_api_gateway_integration" "search_get" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.search.id
  http_method             = aws_api_gateway_method.search_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.search_lambda_invoke_arn
}

# Allow API Gateway to invoke search Lambda
resource "aws_lambda_permission" "allow_apigw_search" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.search_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deployment with a trigger to force redeploy when integration changes
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = sha1(jsonencode({
      resources   = aws_api_gateway_resource.search.id
      method      = aws_api_gateway_method.search_get.id
      integration = aws_api_gateway_integration.search_get.id
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = var.api_stage_name
}
