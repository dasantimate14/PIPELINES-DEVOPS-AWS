resource "aws_ecr_repository" "app" {
  for_each = local.apps

  name = "${var.proyecto}-${each.key}" # devops-final-backend / devops-final-frontend

  # Una etiqueta (el SHA del commit) siempre apunta a la misma imagen: el despliegue
  # es reproducible y nadie puede sobrescribir lo que esta corriendo.
  image_tag_mutability = "IMMUTABLE"

  # Permite "terraform destroy" aunque el repositorio tenga imagenes.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Conservar solo las 10 imagenes mas recientes"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
