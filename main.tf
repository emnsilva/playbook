terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "TFC_AWS_RUN_ROLE_ARN" {
  description = "ARN da role IAM para autenticação OIDC"
  type        = string
}

variable "TFC_AWS_PROVIDER_AUTH" {
  description = "Flag para habilitar autenticação OIDC no provedor AWS"
  type        = bool
  default     = true
}

provider "aws" {
  region = "sa-east-1"  # Substitua pela sua região AWS

  assume_role {
    role_arn = var.TFC_AWS_RUN_ROLE_ARN
  }
}

resource "aws_s3_bucket" "meu_bucket" {
  bucket = "meu-bucket-2025"

  tags = {
    Name        = "MeuBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "meu_bucket_acl" {
  bucket = aws_s3_bucket.meu_bucket.id
  acl    = "private"
}
