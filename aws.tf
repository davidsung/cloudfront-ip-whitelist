terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = "~> 2.8"
  region  = var.aws_region
}

provider "aws" {
  alias   = "us_east_1"
  version = "~> 2.8"
  region  = "us-east-1"
}
