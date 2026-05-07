provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "sctp-ce12-tfstate-bucket" # must exist in AWS
    key    = "state.tfstate"
    region = "ap-southeast-1"
  }
}

# =========================================
# Main bucket resource
resource "aws_s3_bucket" "s3_tf" {
  bucket_prefix = "terraform-aneesh-"
}

# Public access block
resource "aws_s3_bucket_public_access_block" "s3_tf_block" {
  bucket = aws_s3_bucket.s3_tf.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_tf.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/my-key" # replace with your KMS key alias or ARN
    }
  }
}

# Lifecycle configuration (cleanup + abort incomplete uploads)
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Access logging (requires a separate log bucket)
resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "terraform-aneesh-logs-"
}

resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.s3_tf.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}
