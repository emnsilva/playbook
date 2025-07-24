terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provedor para região primária (São Paulo)
provider "aws" {
  alias  = "sa_east"
  region = "sa-east-1"
}

# Provedor para região secundária (Norte da Virgínia)
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

# Bucket na região primária
resource "aws_s3_bucket" "bucket_sa" {
  provider      = aws.sa_east
  bucket        = "meu-bucket-sa-2025"  # Nome deve ser único globalmente
  force_destroy = true
}

# Bucket na região secundária
resource "aws_s3_bucket" "bucket_us" {
  provider      = aws.us_east
  bucket        = "meu-bucket-us-2025"  # Nome deve ser único globalmente
  force_destroy = true
}
