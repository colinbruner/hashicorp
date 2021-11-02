provider "aws" {
  region = var.aws_region
}

# Generate a random string
resource "random_string" "random" {
  length  = 8
  special = false
}

locals {
  # Force lowering of string
  random_string = lower(random_string.random.id)
}


# Configurations for global infrastructure bucket terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.s3_backend_bucket}-${local.random_string}"
  acl    = "private"

  # Enable versioning so we can see the full revision history of our state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "hashicorp.sandbox.terraform.s3.backend"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

