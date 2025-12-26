# DynamoDB table storing image metadata
# PK: ImageID (S)
# GSI: Label-index on attribute "Label" (S) for searching by label/tag
resource "aws_dynamodb_table" "images" {
  name         = "${var.name_prefix}-imagetable"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "ImageID"

  attribute {
    name = "ImageID"
    type = "S"
  }

  attribute {
    name = "Label"
    type = "S"
  }

  global_secondary_index {
    name            = "Label-index"
    hash_key        = "Label"
    projection_type = "ALL"
  }

  tags = merge(var.tags, {
    Component = "dynamodb"
  })
}