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
    description = "Valor del claim sub de los workflows de main, por ejemplo repo:dueno/repo:ref:refs/heads/main"
    type = string
}

validation {
    condition = startswith(var.github_sub, "repo:") && endswith(var.github_sub, ":ref:refs/heads/main")
    error_message = "Debe empezar con repo: y terminar en :ref:refs/heads/main
}