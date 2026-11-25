output "alb_dns" {
  description = "Nombre DNS del ALB"
  value       = aws_lb.principal.dns_name
}

output "alb_url" {
  description = "URL publica de la aplicacion"
  value       = "http://${aws_lb.principal.dns_name}"
}

output "ecr_backend_url" {
  description = "URL del repositorio ECR del backend"
  value       = aws_ecr_repository.app["backend"].repository_url
}

output "ecr_frontend_url" {
  description = "URL del repositorio ECR del frontend"
  value       = aws_ecr_repository.app["frontend"].repository_url
}

output "ecs_cluster" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.principal.name
}

output "ecs_servicio_backend" {
  description = "Nombre del servicio ECS del backend"
  value       = aws_ecs_service.app["backend"].name
}

output "ecs_servicio_frontend" {
  description = "Nombre del servicio ECS del frontend"
  value       = aws_ecs_service.app["frontend"].name
}

output "familia_tarea_backend" {
  description = "Familia de la definicion de tarea del backend"
  value       = aws_ecs_task_definition.app["backend"].family
}

output "familia_tarea_frontend" {
  description = "Familia de la definicion de tarea del frontend"
  value       = aws_ecs_task_definition.app["frontend"].family
}

output "rol_ejecucion_arn" {
  description = "ARN del rol de ejecucion de ECS"
  value       = aws_iam_role.ecs_ejecucion.arn
}
