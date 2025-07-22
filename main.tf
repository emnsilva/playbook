terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Declaração da variável necessária
variable "TFC_AWS_RUN_ROLE_ARN" {
  description = "The ARN of the AWS IAM Role to assume via OIDC"
  type        = string
}

provider "aws" {
  region = "sa-east-1"
  
  assume_role_with_web_identity {
    role_arn                = var.TFC_AWS_RUN_ROLE_ARN
    web_identity_token_file = "/tmp/tfc_jwt.jwt"
    session_name            = "terraform-session"
  }
}

resource "aws_s3_bucket" "meu_bucket" {
  bucket        = "meu-bucket-2025"
  force_destroy = true
}
