resource "aws_ecs_cluster" "principal" {
  name = local.ecs_cluster
}

# Revision inicial de cada definicion de tarea. El Pipeline 3 registra revisiones
# nuevas con la imagen del commit; Terraform solo crea la primera.
resource "aws_ecs_task_definition" "app" {
  for_each = local.apps

  family                   = "${var.proyecto}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_ejecucion.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64" # las imagenes se construyen en runners x86_64
  }

  container_definitions = jsonencode([{
    name      = each.key # "backend" / "frontend": el Pipeline 3 busca este nombre
    image     = "${aws_ecr_repository.app[each.key].repository_url}:bootstrap"
    essential = true

    portMappings = [{
      containerPort = each.value.puerto
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app[each.key].name
        awslogs-region        = var.region
        awslogs-stream-prefix = each.key
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  for_each = local.apps

  name            = "${var.proyecto}-${each.key}"
  cluster         = aws_ecs_cluster.principal.id
  task_definition = aws_ecs_task_definition.app[each.key].arn
  launch_type     = "FARGATE"

  # Nace sin tareas: la imagen ":bootstrap" no existe. El Pipeline 3 sube el conteo
  # cuando ya hay una imagen real en ECR.
  desired_count = 0

  # Tiempo para que la app arranque antes de que el ALB cuente health checks fallidos.
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = aws_subnet.privada[*].id
    security_groups  = [aws_security_group.tareas.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app[each.key].arn
    container_name   = each.key
    container_port   = each.value.puerto
  }

  # Si las tareas nuevas no pasan los health checks, ECS detiene el despliegue y
  # vuelve a la revision anterior.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # El Pipeline 3 cambia la revision y el conteo; sin esto, cada "terraform apply"
  # los devolveria a ":bootstrap" y a 0 tareas.
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  # Un servicio con load_balancer exige que el target group ya este asociado a un
  # listener. No hay referencia directa al listener, asi que la dependencia es explicita.
  depends_on = [aws_lb_listener.http, aws_lb_listener_rule.api]
}
