data "aws_caller_identity" "current" {}

locals {
  // Prefix ensures uniqueness per AWS account
  name_prefix = "${var.project_name}-${data.aws_caller_identity.current.account_id}"

  // Centralized tagging if you want to extend later
  common_tags = {
    Project     = var.project_name
    Environment = "default"
    ManagedBy   = "terraform"
    AccountId   = data.aws_caller_identity.current.account_id
  }
}