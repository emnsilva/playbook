terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"  # Altere para sua região
}

resource "aws_s3_bucket" "meu_bucket" {
  bucket = "meu-bucket-2025"
  force_destroy = true
}