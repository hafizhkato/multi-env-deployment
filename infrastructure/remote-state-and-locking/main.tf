provider "aws" {
  region = var.aws_region
  profile = "default"
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "multi-env-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Lock Table"
    Environment = "Global"
    Purpose     = "Terraform State Locking"
  }
}

resource "aws_s3_bucket" "remote_state" {
  bucket = "multi-env-terraform-state-997"
  force_destroy = true
}
