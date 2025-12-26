#################################
# Package Lambda Code with archive_file
#################################

data "archive_file" "image_labeler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/image_labeler"
  output_path = "${path.module}/image_labeler.zip"
}

data "archive_file" "search_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/search"
  output_path = "${path.module}/search.zip"
}


#################################
# Lambda Functions
#################################

resource "aws_lambda_function" "image_labeler" {
  function_name = "${var.name_prefix}-image-labeler"
  role          = var.lambda_image_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.image_labeler_zip.output_path
  source_code_hash = data.archive_file.image_labeler_zip.output_base64sha256

  memory_size = var.lambda_memory_mb
  timeout     = var.lambda_timeout_seconds

  environment {
    variables = {
      TABLE_NAME    = var.table_name
      REGION        = var.aws_region
      PHOTOS_BUCKET = var.photos_bucket_name
    }
  }

  tags = merge(var.tags, {
    Component = "lambda-image-labeler"
  })
}

resource "aws_lambda_function" "search" {
  function_name = "${var.name_prefix}-search"
  role          = var.lambda_search_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = data.archive_file.search_zip.output_path
  source_code_hash = data.archive_file.search_zip.output_base64sha256

  memory_size = var.lambda_memory_mb
  timeout     = var.lambda_timeout_seconds

  environment {
    variables = {
      TABLE_NAME = var.table_name
      REGION     = var.aws_region
    }
  }

  tags = merge(var.tags, {
    Component = "lambda-search"
  })
}

#################################
# S3 -> Image Labeler Lambda Trigger
#################################

resource "aws_lambda_permission" "allow_s3_image_upload" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_labeler.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.photos_bucket_arn
}

resource "aws_s3_bucket_notification" "photos_events" {
  bucket = var.photos_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_labeler.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "images/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_image_upload,
    aws_lambda_function.image_labeler
  ]
}
