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
    bucket = "sctp-ce12-tfstate-bucket" # Change this
    key    = "state.tfstate"            # Change this
    region = "ap-southeast-1"
  }
}

resource "aws_s3_bucket" "s3_tf" {
  bucket_prefix = "terraform-aneesh-" # Set your bucket name here
}

# =========================================
# checkov CL2_AWS_6: s3 public access block
resource "aws_s3_bucket_public_access_block" "s3_tf_block" {
  bucket = aws_s3_bucket.s3_tf.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# checkov CK_AWS_21: enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_tf.id

  versioning_configuration {
    status = "Enabled"
  }
}

# checkov CK_AWS_145: enable encryption (sse-s3 minimal)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# checkov CK2_AWS_61: lifecycle configuration required
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}
