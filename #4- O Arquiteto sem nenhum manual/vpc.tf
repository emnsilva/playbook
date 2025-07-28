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
  region = "sa-east-1"  
  alias  = "sp"         
}

provider "aws" {
  region = "us-east-1"  
  alias  = "va"         
}

# Agora sim podemos chamar cada um pelo apelido!
resource "aws_vpc" "main" {
  provider = aws.sp
  cidr_block = "10.0.0.0/16"
  tags = { Name = "main" }
}

resource "aws_vpc" "backup" {
  provider = aws.va
  cidr_block = "10.1.0.0/16"
  tags = { Name = "backup" }
}
