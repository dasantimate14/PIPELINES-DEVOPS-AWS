# Sin NAT Gateway, las tareas privadas llegan a los servicios de AWS por endpoints:
#   ecr.api -> autenticacion y manifiestos de ECR
#   ecr.dkr -> protocolo de registro Docker (docker pull)
#   logs    -> driver awslogs hacia CloudWatch Logs
#   s3      -> las capas de las imagenes de ECR se descargan desde S3

resource "aws_vpc_endpoint" "interfaz" {
  for_each = toset(["ecr.api", "ecr.dkr", "logs"])

  vpc_id            = aws_vpc.principal.id
  service_name      = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type = "Interface"

  # DNS privado: el nombre publico del servicio resuelve a la IP privada del endpoint,
  # asi el agente de ECS no necesita configuracion especial.
  private_dns_enabled = true

  subnet_ids         = local.subredes_endpoints
  security_group_ids = [aws_security_group.endpoints.id]

  tags = { Name = "${var.proyecto}-vpce-${replace(each.key, ".", "-")}" }
}

# Gateway: no crea ENI ni cuesta por hora; agrega a la tabla privada una ruta hacia
# la lista de prefijos de S3.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.principal.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.privada.id]

  tags = { Name = "${var.proyecto}-vpce-s3" }
}
