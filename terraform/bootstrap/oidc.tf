# Registra un emisor externo de tokens OIDC como identidad de confianza.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # Audiencias aceptadas: el valor que el emisor pondrá en el claim "aud".
  client_id_list = ["sts.amazonaws.com"]
}