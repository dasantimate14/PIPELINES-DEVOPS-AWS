# Valores que se copian a variables de GitHub (Settings > Secrets and variables > Actions > Variables).

output "s3_bucket_name" {
  description = "Nombre del bucket del estado de terraform/infra/ (variable TF_STATE_BUCKET)"
  value       = aws_s3_bucket.estado.bucket
}

output "rol_infra_arn" {
  description = "ARN del rol del pipeline 1, terraform de infra (variable AWS_ROLE_INFRA)"
  value       = aws_iam_role.gh_infra.arn
}

output "rol_build_arn" {
  description = "ARN del rol del pipeline 2, build y push a ECR (variable AWS_ROLE_BUILD)"
  value       = aws_iam_role.gh_build.arn
}

output "rol_deploy_arn" {
  description = "ARN del rol del pipeline 3, despliegue en ECS (variable AWS_ROLE_DEPLOY)"
  value       = aws_iam_role.gh_deploy.arn
}
