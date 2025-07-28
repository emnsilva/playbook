terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Versão CERTA - Com alias (apelido)
provider "aws" {
  region = "sa-east-1"  # Zé Paulista
  alias  = "sp"         # Apelido pra não confundir
}

provider "aws" {
  region = "us-east-1"  # Zé Americano
  alias  = "va"         # Outro apelido
}

# Agora sim podemos chamar cada um pelo apelido!
resource "aws_vpc" "main" {
  provider = aws.sp  # Esse é o Zé Paulista
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "backup" {
  provider = aws.va  # Esse é o Zé Americano
  cidr_block = "10.1.0.0/16"
}
