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
    bucket = "sctp-ce12-tfstate-bucket"
    key    = "state.tfstate"
    region = "ap-southeast-1"
  }
}

# =========================================
# Main bucket
resource "aws_s3_bucket" "s3_tf" {
  bucket_prefix = "terraform-aneesh-"
}

# Public access block
resource "aws_s3_bucket_public_access_block" "s3_tf_block" {
  bucket                  = aws_s3_bucket.s3_tf.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "s3_tf_versioning" {
  bucket = aws_s3_bucket.s3_tf.id
  versioning_configuration { status = "Enabled" }
}

# KMS encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_tf_encryption" {
  bucket = aws_s3_bucket.s3_tf.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/my-key"
    }
  }
}

# Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "s3_tf_lifecycle" {
  bucket = aws_s3_bucket.s3_tf.id
  rule {
    id     = "cleanup"
    status = "Enabled"
    expiration { days = 90 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

# =========================================
# Log bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "terraform-aneesh-logs-"
}

# Public access block
resource "aws_s3_bucket_public_access_block" "log_bucket_block" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning
resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration { status = "Enabled" }
}

# KMS encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/my-key"
    }
  }
}

# Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    id     = "log-cleanup"
    status = "Enabled"
    expiration { days = 180 }
    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

# Access logging (main bucket logs into log bucket)
resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.s3_tf.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "logs/"
}

# Event notifications (example Lambda trigger)
resource "aws_s3_bucket_notification" "log_bucket_notify" {
  bucket = aws_s3_bucket.log_bucket.id
  lambda_function {
    lambda_function_arn = "arn:aws:lambda:ap-southeast-1:123456789012:function:processLogs"
    events              = ["s3:ObjectCreated:*"]
  }
}

# Replication (example to another bucket in another region)
resource "aws_s3_bucket_replication_configuration" "log_bucket_replication" {
  bucket = aws_s3_bucket.log_bucket.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-logs"
    status = "Enabled"
    destination {
      bucket        = "arn:aws:s3:::aneesh-log-bucket-backup"
      storage_class = "STANDARD"
    }
  }
}
