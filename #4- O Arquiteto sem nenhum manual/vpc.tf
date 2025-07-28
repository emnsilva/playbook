# 1. Configura as regiões
provider "aws" { region = "sa-east-1" }  # Nuvem de SP
provider "aws" { region = "us-east-1" }  # Nuvem dos EUA

# 2. Cria duas VPCs (redes privadas)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # Rede grande em SP
  tags = { Name = "Casa-Digital" }  # Coloca nome
}

resource "aws_vpc" "backup" {
  cidr_block = "10.1.0.0/16"  # Rede gêmea nos EUA
  tags = { Name = "Casa-de-Veraneio" }  # Nome diferente
}
