terraform {
  backend "s3" {
    bucket         = "multi-env-terraform-state-997"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "multi-env-tfstate-lock"
    encrypt        = true
  }
}