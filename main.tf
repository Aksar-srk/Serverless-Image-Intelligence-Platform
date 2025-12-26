module "s3" {
  source      = "./modules/s3"
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "dynamodb" {
  source      = "./modules/dynamodb"
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix = local.name_prefix
  tags        = local.common_tags

  photos_bucket_arn  = module.s3.photos_bucket_arn
  dynamodb_table_arn = module.dynamodb.table_arn
}

module "lambda" {
  source = "./modules/lambda"

  name_prefix = local.name_prefix
  tags        = local.common_tags

  aws_region = var.aws_region

  lambda_memory_mb       = var.lambda_memory_mb
  lambda_timeout_seconds = var.lambda_timeout_seconds

  photos_bucket_name = module.s3.photos_bucket_name
  photos_bucket_arn  = module.s3.photos_bucket_arn

  table_name = module.dynamodb.table_name

  lambda_image_role_arn  = module.iam.lambda_image_role_arn
  lambda_search_role_arn = module.iam.lambda_search_role_arn
}

module "apigateway" {
  source = "./modules/apigateway"

  name_prefix    = local.name_prefix
  api_stage_name = var.api_stage_name

  search_lambda_invoke_arn = module.lambda.search_invoke_arn
  search_lambda_name       = module.lambda.search_name
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  tags = local.common_tags

  image_labeler_name = module.lambda.image_labeler_name
  search_name        = module.lambda.search_name
  api_gateway_name   = module.apigateway.api_name
}
