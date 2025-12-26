#################################
# Common Lambda Assume Role Policy
#################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#################################
# Image Labeler Lambda Role & Policies
#################################

resource "aws_iam_role" "lambda_image_role" {
  name               = "${var.name_prefix}-image-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.tags, {
    Component = "lambda-image-role"
  })
}

# Basic execution role for CloudWatch logging
resource "aws_iam_role_policy_attachment" "image_logs" {
  role       = aws_iam_role.lambda_image_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least-privilege policy for Image Labeler Lambda
data "aws_iam_policy_document" "image_policy" {

  # Read uploaded images from photos bucket
  statement {
    sid    = "S3ReadImages"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${var.photos_bucket_arn}/images/*"
    ]
  }

  # Use Rekognition to detect labels
  statement {
    sid    = "UseRekognition"
    effect = "Allow"

    actions = [
      "rekognition:DetectLabels"
    ]

    resources = ["*"]
  }

  # Write metadata into DynamoDB table
  statement {
    sid    = "WriteDynamo"
    effect = "Allow"

    actions = [
      "dynamodb:PutItem"
    ]

    resources = [
      var.dynamodb_table_arn
    ]
  }
}

resource "aws_iam_policy" "image_policy" {
  name   = "${var.name_prefix}-image-lambda-policy"
  policy = data.aws_iam_policy_document.image_policy.json
}

resource "aws_iam_role_policy_attachment" "image_custom" {
  role       = aws_iam_role.lambda_image_role.name
  policy_arn = aws_iam_policy.image_policy.arn
}

#################################
# Search Lambda Role & Policies
#################################

resource "aws_iam_role" "lambda_search_role" {
  name               = "${var.name_prefix}-search-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.tags, {
    Component = "lambda-search-role"
  })
}

resource "aws_iam_role_policy_attachment" "search_logs" {
  role       = aws_iam_role.lambda_search_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "search_policy" {
  statement {
    sid    = "ReadDynamo"
    effect = "Allow"

    actions = [
      "dynamodb:Query",
      "dynamodb:Scan"
    ]

    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "search_policy" {
  name   = "${var.name_prefix}-search-lambda-policy"
  policy = data.aws_iam_policy_document.search_policy.json
}

resource "aws_iam_role_policy_attachment" "search_custom" {
  role       = aws_iam_role.lambda_search_role.name
  policy_arn = aws_iam_policy.search_policy.arn
}
