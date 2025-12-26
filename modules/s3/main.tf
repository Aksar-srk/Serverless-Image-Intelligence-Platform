#############################################
# S3 bucket for storing uploaded photos
#############################################
resource "aws_s3_bucket" "photos" {
  bucket = "${var.name_prefix}-photos"

  tags = merge(var.tags, {
    Component = "photos-bucket"
  })
}

# Allow browser uploads & public reads
resource "aws_s3_bucket_public_access_block" "photos" {
  bucket = aws_s3_bucket.photos.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# CORS settings so front-end browser PUT upload works
resource "aws_s3_bucket_cors_configuration" "photos" {
  bucket = aws_s3_bucket.photos.id

  cors_rule {
    allowed_methods = ["GET", "PUT", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Public read + write (Demo only!)
# Enables browser PUT uploads and GET for gallery rendering
resource "aws_s3_bucket_policy" "photos_public" {
  depends_on = [aws_s3_bucket_public_access_block.photos]

  bucket = aws_s3_bucket.photos.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadWritePhotos"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.photos.arn}/*"
      }
    ]
  })
}

#############################################
# S3 bucket for static website hosting (frontend)
#############################################
resource "aws_s3_bucket" "web" {
  bucket = "${var.name_prefix}-web"

  tags = merge(var.tags, {
    Component = "web-bucket"
  })
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "web" {
  bucket = aws_s3_bucket.web.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "web_public" {
  depends_on = [aws_s3_bucket_public_access_block.web]

  bucket = aws_s3_bucket.web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = "${aws_s3_bucket.web.arn}/*"
      }
    ]
  })
}
