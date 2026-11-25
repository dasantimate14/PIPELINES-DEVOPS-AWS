locals {
  account_id = data.aws_caller_identity.actual.account_id

  # Nombres que terraform/infra/
  ecs_cluster        = var.proyecto
  ecs_servicios      = ["${var.proyecto}-backend", "${var.proyecto}-frontend"]
  ecs_rol_ejecucion  = "${var.proyecto}-ecs-ejecucion"
  ecr_repositorios   = ["${var.proyecto}-backend", "${var.proyecto}-frontend"]
  ecr_repos_arn      = [for r in local.ecr_repositorios : "arn:aws:ecr:${var.region}:${local.account_id}:repository/${r}"]
  ecs_servicios_arn  = [for s in local.ecs_servicios : "arn:aws:ecs:${var.region}:${local.account_id}:service/${local.ecs_cluster}/${s}"]
  rol_ejecucion_arn  = "arn:aws:iam::${local.account_id}:role/${local.ecs_rol_ejecucion}"
  roles_ecs_patron   = "arn:aws:iam::${local.account_id}:role/${var.proyecto}-ecs-*"
  politica_ejecucion = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  # Politica de confianza comun: solo la rama main de mi repo, via OIDC de GitHub.
  confianza_github = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = var.github_sub
        }
      }
    }]
  })
}

# ---------------------------------------------------------------------------
# Pipeline 1: Terraform de terraform/infra/
# ---------------------------------------------------------------------------
resource "aws_iam_role" "gh_infra" {
  name               = "${var.proyecto}-gh-infra"
  description        = "Pipeline 1: terraform de infra"
  assume_role_policy = local.confianza_github
}

resource "aws_iam_role_policy_attachment" "gh_infra_poweruser" {
  role       = aws_iam_role.gh_infra.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_role_policy" "gh_infra_iam" {
  name = "${var.proyecto}-gh-infra-iam"
  role = aws_iam_role.gh_infra.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Ciclo de vida de los roles de ECS. El patron devops-final-ecs-* excluye
        # a devops-final-gh-*, asi este rol no puede modificarse a si mismo.
        Sid    = "AdministrarRolesEcs"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
        ]
        Resource = local.roles_ecs_patron
      },
      {
        # Solo puede adjuntar/quitar la politica de ejecucion de ECS.
        Sid      = "AdjuntarPoliticaEjecucion"
        Effect   = "Allow"
        Action   = ["iam:AttachRolePolicy", "iam:DetachRolePolicy"]
        Resource = local.roles_ecs_patron
        Condition = {
          ArnEquals = { "iam:PolicyARN" = local.politica_ejecucion }
        }
      },
      {
        # Pasar los roles de ECS unicamente al servicio de tareas de ECS.
        Sid      = "PasarRolesEcs"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = local.roles_ecs_patron
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# Pipeline 2: build y push de imagenes a ECR
# ---------------------------------------------------------------------------
resource "aws_iam_role" "gh_build" {
  name               = "${var.proyecto}-gh-build"
  description        = "Pipeline 2: build y push a ECR"
  assume_role_policy = local.confianza_github
}

resource "aws_iam_role_policy" "gh_build_ecr" {
  name = "${var.proyecto}-gh-build-ecr"
  role = aws_iam_role.gh_build.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # No acepta ARN de recurso.
        Sid      = "LoginEcr"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "PushYLectura"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeImageScanFindings",
        ]
        Resource = local.ecr_repos_arn
      },
    ]
  })
}

# ---------------------------------------------------------------------------
# Pipeline 3: despliegue en ECS
# ---------------------------------------------------------------------------
resource "aws_iam_role" "gh_deploy" {
  name               = "${var.proyecto}-gh-deploy"
  description        = "Pipeline 3: despliegue en ECS"
  assume_role_policy = local.confianza_github
}

resource "aws_iam_role_policy" "gh_deploy_ecs" {
  name = "${var.proyecto}-gh-deploy-ecs"
  role = aws_iam_role.gh_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Estas acciones no aceptan ARN de recurso.
        Sid    = "TaskDefinitionsYLecturasAlb"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "elasticloadbalancing:Describe*",
        ]
        Resource = "*"
      },
      {
        Sid      = "ActualizarServicios"
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = local.ecs_servicios_arn
      },
      {
        # RegisterTaskDefinition con executionRoleArn exige PassRole sobre ese rol.
        Sid      = "PasarRolEjecucion"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = local.rol_ejecucion_arn
        Condition = {
          StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" }
        }
      },
      {
        Sid      = "VerificarImagen"
        Effect   = "Allow"
        Action   = "ecr:DescribeImages"
        Resource = local.ecr_repos_arn
      },
    ]
  })
}
