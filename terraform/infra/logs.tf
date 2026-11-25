# Se crean aqui (y no dejando que ECS los cree) para controlar la retencion y para
# que "terraform destroy" los elimine.
resource "aws_cloudwatch_log_group" "app" {
  for_each = local.apps

  name              = "/ecs/${var.proyecto}-${each.key}"
  retention_in_days = 7
}
