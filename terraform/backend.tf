terraform {
  required_providers {
    jwks = {
      source  = "iwarapter/jwks"
      version = "~> 0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
