provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    bucket = "sctp-ce12-tfstate-bucket"
    key    = "aneesh-s3buckets.tfstate"
    region = "ap-southeast-1"
  }
}

resource "aws_s3_bucket" "s3_tf" {
  #checkov:skip=CKV2_AWS_62
  #checkov:skip=CKV2_AWS_6
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV_AWS_21
  #checkov:skip=CKV_AWS_145
  bucket_prefix = "aneesh-s3buckets"
}

terraform {
  required_version = ">= 1.5.0, < 2.0.0"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.44.0"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_lifecycle_configuration" "s3_tf_lifecycle" {
  #checkov:skip=CKV2_AWS_61
  #checkov:skip=CKV_AWS_300
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket" "logging" {
  #checkov:skip=CKV2_AWS_62
  #checkov:skip=CKV2_AWS_6
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV_AWS_21
  #checkov:skip=CKV_AWS_145
  #checkov:skip=CKV2_AWS_61
  bucket = "aneesh-ce12-32-logging-bucket"
}

data "aws_iam_policy_document" "logging_bucket_policy" {
  statement {
    principals {
      identifiers = ["logging.s3.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logging.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logging.bucket
  policy = data.aws_iam_policy_document.logging_bucket_policy.json
}

resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.s3_tf.bucket

  target_bucket = aws_s3_bucket.logging.bucket
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}
