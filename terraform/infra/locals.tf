locals {
  # Las dos primeras zonas disponibles de la region.
  azs = slice(data.aws_availability_zones.disponibles.names, 0, 2)

  # Nombres que el rol devops-final-gh-deploy (terraform/bootstrap/roles.tf) tiene permitidos.
  # Si cambias alguno aqui, cambialo tambien alli.
  ecs_cluster       = var.proyecto
  ecs_rol_ejecucion = "${var.proyecto}-ecs-ejecucion"

  # Las dos aplicaciones. ECR, logs, target groups, tareas y servicios se crean con
  # for_each sobre este mapa, asi ambas comparten exactamente la misma configuracion.
  apps = {
    backend = {
      puerto       = 8000
      health_check = "/api/health"
    }
    frontend = {
      puerto       = 8080
      health_check = "/"
    }
  }

  # Subredes donde viven las ENI de los VPC endpoints de interfaz (ver variables.tf).
  subredes_endpoints = var.endpoints_en_todas_las_zonas ? aws_subnet.privada[*].id : [aws_subnet.privada[0].id]
}
