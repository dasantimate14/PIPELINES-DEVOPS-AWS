# Tres Security Groups encadenados: internet -> ALB -> tareas -> endpoints.
# Cada regla es un recurso separado. Al crear un SG, Terraform elimina la regla de
# salida "todo permitido" que AWS agrega por defecto, asi que toda salida es explicita.

resource "aws_security_group" "alb" {
  name        = "${var.proyecto}-alb-sg"
  description = "ALB publico: HTTP desde internet hacia las tareas"
  vpc_id      = aws_vpc.principal.id
  tags        = { Name = "${var.proyecto}-alb-sg" }
}

resource "aws_security_group" "tareas" {
  name        = "${var.proyecto}-tareas-sg"
  description = "Tareas ECS: solo trafico desde el ALB"
  vpc_id      = aws_vpc.principal.id
  tags        = { Name = "${var.proyecto}-tareas-sg" }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.proyecto}-endpoints-sg"
  description = "VPC endpoints de interfaz: HTTPS desde las tareas"
  vpc_id      = aws_vpc.principal.id
  tags        = { Name = "${var.proyecto}-endpoints-sg" }
}

# --- ALB --------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP desde internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_a_tareas" {
  for_each = local.apps

  security_group_id            = aws_security_group.alb.id
  description                  = "ALB hacia ${each.key}"
  referenced_security_group_id = aws_security_group.tareas.id
  ip_protocol                  = "tcp"
  from_port                    = each.value.puerto
  to_port                      = each.value.puerto
}

# --- Tareas -----------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "tareas_desde_alb" {
  for_each = local.apps

  security_group_id            = aws_security_group.tareas.id
  description                  = "${each.key} desde el ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = each.value.puerto
  to_port                      = each.value.puerto
}

# Salida abierta a cualquier destino y protocolo. Es aceptable porque las subredes
# privadas no tienen ruta 0.0.0.0/0 (ni IGW ni NAT): aunque la regla lo permita, el
# trafico solo puede llegar a destinos dentro de la VPC (endpoints de interfaz) y a
# S3 por el endpoint gateway, cuyas IP publicas no caben en un CIDR fijo. La tabla de
# rutas es el control real; restringir aqui solo agregaria reglas fragiles.
resource "aws_vpc_security_group_egress_rule" "tareas_salida" {
  security_group_id = aws_security_group.tareas.id
  description       = "Salida (limitada por la tabla de rutas privada)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --- Endpoints --------------------------------------------------------------
# Sin regla de salida: los SG tienen estado, asi que las respuestas a conexiones
# entrantes se permiten automaticamente. El endpoint nunca inicia conexiones.
resource "aws_vpc_security_group_ingress_rule" "endpoints_desde_tareas" {
  security_group_id            = aws_security_group.endpoints.id
  description                  = "HTTPS desde las tareas"
  referenced_security_group_id = aws_security_group.tareas.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}
