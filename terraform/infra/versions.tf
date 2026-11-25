terraform {
  # 1.11+: use_lockfile del backend S3 ya es estable (sin DynamoDB).
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Etiquetas que el proveedor agrega a todos los recursos que las admiten.
  default_tags {
    tags = {
      Proyecto      = var.proyecto
      GestionadoPor = "terraform"
    }
  }
}
