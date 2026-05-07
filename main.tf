provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  backend "s3" {
    bucket = "sctp-ce12-tfstate-bucket"
    key    = "aneesh-terraform-3.2.tfstate"
    region = "ap-southeast-1"
  }
}

resource "aws_s3_bucket" "s3_tf" {
  bucket_prefix = "aneesh-terraform-3.2" # Set your bucket name here
}
