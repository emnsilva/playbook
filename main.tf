terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use a versão mais recente conforme necessário
    }
  }
}

# Declaração das variáveis
variable "TFC_AWS_RUN_ROLE_ARN" {
  description = "ARN da role IAM para autenticação OIDC"
  type        = string
}

variable "TFC_AWS_PROVIDER_AUTH" {
  description = "Flag para habilitar autenticação OIDC no provedor AWS"
  type        = bool
  default     = true
}

# Configuração do provedor AWS
provider "aws" {
  region = "sa-east-1"  # Substitua pela sua região AWS

  # Configuração para assumir uma role usando OIDC
  assume_role {
    role_arn = var.TFC_AWS_RUN_ROLE_ARN
    # Se necessário, você pode especificar uma sessão ou uma política externa aqui
    # session_name = "terraform-session"
    # external_id   = "seu_external_id"
  }
}

# Exemplo de recurso: Criação de um bucket S3
resource "aws_s3_bucket" "meu_bucket" {
  bucket = "meu-bucket-2025"
  acl    = "private"

  tags = {
    Name        = "MeuBucket"
    Environment = "Dev"
  }
}
