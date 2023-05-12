# Configure provider
provider "aws" {
  region  = "us-east-1"
  profile = "terraform-user"
}

# store terraform state file in s3
terraform {
  backend "s3" {
    bucket = "george-terraform-remote-state"
    key    = "terraform.tfstate.dev"
    region = "us-east-1"
    profile = "terraform-user"
  }
}
