# Estado remoto en el bucket creado por terraform/bootstrap/.
# El bloque backend se evalúa antes que las variables, así que no admite var.*:
# bucket y region se pasan en "terraform init" con -backend-config.
terraform {
  backend "s3" {
    key          = "infra/terraform.tfstate"
    use_lockfile = true # bloqueo con un objeto .tflock en S3, sin DynamoDB
    encrypt      = true
  }
}
