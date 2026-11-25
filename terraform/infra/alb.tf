resource "aws_lb" "principal" {
  name               = "${var.proyecto}-alb"
  load_balancer_type = "application"
  internal           = false # internet-facing
  subnets            = aws_subnet.publica[*].id
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "app" {
  for_each = local.apps

  name     = "${var.proyecto}-${each.key}-tg"
  port     = each.value.puerto
  protocol = "HTTP"
  vpc_id   = aws_vpc.principal.id

  # Fargate con awsvpc: cada tarea tiene su propia ENI e IP, sin instancia EC2.
  target_type = "ip"

  # Segundos que el ALB espera antes de dar de baja una tarea vieja (default 300).
  deregistration_delay = 30

  health_check {
    path    = each.value.health_check
    matcher = "200"
    port    = "traffic-port"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.principal.arn
  port              = 80
  protocol          = "HTTP"

  # Todo lo que no coincida con una regla va al frontend.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["frontend"].arn
  }
}

# El frontend llama a la API con rutas relativas (/api/...), asi que ambos comparten
# el dominio del ALB y no hace falta CORS.
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app["backend"].arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
