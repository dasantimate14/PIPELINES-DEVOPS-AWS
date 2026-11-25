# Terraform

| Carpeta | Qué crea | Estado | Quién lo aplica |
|---|---|---|---|
| `bootstrap/` | Bucket del estado, proveedor OIDC de GitHub y los 3 roles de los pipelines | Local (`terraform.tfstate`, no se sube a git) | Tú, una sola vez, desde tu equipo |
| `infra/` | VPC, endpoints, ECR, logs, rol de ejecución, ALB y ECS | Remoto en S3 (`infra/terraform.tfstate`) | Pipeline 1 (o tú, para pruebas) |

`bootstrap/` debe estar aplicado antes de `infra/`.

## infra/ desde PowerShell

```powershell
cd terraform/infra
$env:AWS_PROFILE = "devops-final"
aws sts get-caller-identity --query Arn --output text   # confirma la identidad
```

### Inicializar

El bloque `backend "s3"` no acepta variables, así que el bucket y la región se pasan aquí.
El nombre del bucket es el output `s3_bucket_name` de `bootstrap/`.

```powershell
# Comillas obligatorias en PowerShell 5.1: sin ellas parte "-chdir=..." en dos argumentos.
$bucket = terraform "-chdir=../bootstrap" output -raw s3_bucket_name
if (-not $bucket) { throw "No se obtuvo el nombre del bucket" }
terraform init -backend-config="bucket=$bucket" -backend-config="region=us-east-1"
```

### Planificar y aplicar

```powershell
terraform fmt -check -recursive
terraform validate
terraform plan -out=infra.tfplan
terraform apply infra.tfplan
terraform output
```

### Destruir

```powershell
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan      # equivalente a: terraform destroy
```

Los repositorios ECR tienen `force_delete = true`, así que se borran aunque tengan imágenes.
El bucket del estado (de `bootstrap/`) no se toca.

## Por qué los servicios nacen con 0 tareas

Terraform crea la primera revisión de cada definición de tarea con la imagen
`<repositorio>:bootstrap`, que no existe. Con `desired_count = 0`, ECS no intenta
ejecutar ninguna tarea, así que no hay errores de descarga de imagen.

El flujo real es:

1. **Pipeline 1** crea la infraestructura (servicios con 0 tareas).
2. **Pipeline 2** publica las imágenes en ECR con el SHA del commit como etiqueta.
3. **Pipeline 3** registra una revisión nueva de cada definición de tarea con esa imagen
   y actualiza el servicio (revisión y número de tareas).

Los servicios tienen `lifecycle { ignore_changes = [task_definition, desired_count] }`,
así que un `terraform apply` posterior no revierte lo que desplegó el Pipeline 3.

## Nota para Windows

Si `terraform validate` o `plan` fallan con `x509: certificate signed by unknown authority`,
algo en el equipo intercepta la conexión local entre Terraform y su proveedor.
Alternativa: ejecutar Terraform en Docker, montando el perfil de AWS en solo lectura:

```powershell
docker run --rm -it -v "${PWD}:/work" -v "$env:USERPROFILE\.aws:/root/.aws:ro" `
  -e AWS_PROFILE=devops-final -w /work hashicorp/terraform:1.11.4 <comando>
```
