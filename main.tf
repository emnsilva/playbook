terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
  # Não precisa de nenhuma configuração extra - pega credenciais das variáveis env automaticamente
}

resource "aws_s3_bucket" "meu_bucket" {
  bucket        = "meu-bucket-2025-unico" # Adicione algo único
  force_destroy = true
}
