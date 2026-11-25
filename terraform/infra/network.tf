data "aws_availability_zones" "disponibles" {
  state = "available"
}

resource "aws_vpc" "principal" {
  cidr_block = var.vpc_cidr

  # Ambos son obligatorios para que los VPC endpoints de interfaz con DNS privado
  # resuelvan api.ecr.us-east-1.amazonaws.com, etc. hacia sus IP privadas.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.proyecto}-vpc" }
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id
  tags   = { Name = "${var.proyecto}-igw" }
}

# ---------------------------------------------------------------------------
# Subredes publicas: solo el ALB
# ---------------------------------------------------------------------------
resource "aws_subnet" "publica" {
  count = length(local.azs)

  vpc_id            = aws_vpc.principal.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index) # 10.0.0.0/24, 10.0.1.0/24

  tags = { Name = "${var.proyecto}-publica-${local.azs[count.index]}" }
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.principal.id
  tags   = { Name = "${var.proyecto}-rt-publica" }
}

resource "aws_route" "publica_internet" {
  route_table_id         = aws_route_table.publica.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.principal.id
}

resource "aws_route_table_association" "publica" {
  count = length(aws_subnet.publica)

  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}

# ---------------------------------------------------------------------------
# Subredes privadas: tareas de ECS, sin IP publica y sin salida a internet
# ---------------------------------------------------------------------------
resource "aws_subnet" "privada" {
  count = length(local.azs)

  vpc_id            = aws_vpc.principal.id
  availability_zone = local.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 10 + count.index) # 10.0.10.0/24, 10.0.11.0/24

  tags = { Name = "${var.proyecto}-privada-${local.azs[count.index]}" }
}

# Sin ruta 0.0.0.0/0: solo la ruta local de la VPC y la del endpoint gateway de S3.
resource "aws_route_table" "privada" {
  vpc_id = aws_vpc.principal.id
  tags   = { Name = "${var.proyecto}-rt-privada" }
}

resource "aws_route_table_association" "privada" {
  count = length(aws_subnet.privada)

  subnet_id      = aws_subnet.privada[count.index].id
  route_table_id = aws_route_table.privada.id
}
