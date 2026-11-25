# Rol de EJECUCION: lo usa el agente de ECS (no la aplicacion) para descargar la
# imagen de ECR y escribir en CloudWatch Logs. No hay rol de TAREA porque la
# aplicacion no llama a ninguna API de AWS.
resource "aws_iam_role" "ecs_ejecucion" {
  name        = local.ecs_rol_ejecucion
  description = "Rol de ejecucion de las tareas ECS de ${var.proyecto}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ejecucion" {
  role       = aws_iam_role.ecs_ejecucion.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
