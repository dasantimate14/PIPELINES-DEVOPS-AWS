variable "region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Prefijo de todos los nombres de recursos (debe coincidir con terraform/bootstrap/)"
  type        = string
  default     = "devops-final"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "endpoints_en_todas_las_zonas" {
  description = <<-EOT
    false: los VPC endpoints de interfaz se crean en una sola subred privada (1 ENI por endpoint).
    true: se crean en ambas subredes privadas (2 ENI por endpoint).
    Trade-off: cada ENI de endpoint cuesta por hora. Con una sola zona se paga la mitad, pero si
    esa zona falla las tareas de la otra zona no pueden descargar imagenes ni enviar logs, y el
    trafico entre zonas tiene un pequeno costo de transferencia. Para un proyecto academico basta
    con false; en produccion se usaria true.
  EOT
  type        = bool
  default     = false
}
