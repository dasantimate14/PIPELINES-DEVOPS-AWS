variable "region" {
    description = "Region de AWS"
    type = string
    default = "us-east-1"
}

variable "proyecto" {
    description = "prefijo de todos los nombre de los recursos"
    type = string
    default = "devops-final"
}

variable "github_sub" {
    description = "Valor del claim sub de los workflows de main. Formato nuevo (repos creados desde el 15-jul-2026): repo:dueno@ORGID/repo@REPOID:ref:refs/heads/main. Formato anterior: repo:dueno/repo:ref:refs/heads/main"
    type = string
    validation {
        # can() devuelve false si regex() falla (no hay coincidencia), en vez de lanzar un error.
        # Primera regex: formato anterior. Segunda regex: formato nuevo con IDs numericos.
        condition = (
            can(regex("^repo:[A-Za-z0-9-]+/[A-Za-z0-9._-]+:ref:refs/heads/main$", var.github_sub)) ||
            can(regex("^repo:[A-Za-z0-9-]+@[0-9]+/[A-Za-z0-9._-]+@[0-9]+:ref:refs/heads/main$", var.github_sub))
        )
        error_message = "Debe tener el formato repo:dueno/repo:ref:refs/heads/main o repo:dueno@ORGID/repo@REPOID:ref:refs/heads/main."
    }
}

variable "profile" {
    description = "Nombre del perfil con los permisos minimos"
    type = string
    default = null
}