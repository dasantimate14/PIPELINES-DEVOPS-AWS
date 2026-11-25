#!/usr/bin/env bash
# Prueba de humo posterior al despliegue (la ejecuta el Pipeline 3).
#
# Comprueba, a traves del ALB, que:
#   1. el frontend (/) y el backend (/api/health) responden 200;
#   2. /api/version devuelve exactamente la etiqueta desplegada.
#
# Uso: ETIQUETA=<sha completo> bash pipelines/scripts/smoke-test.sh
# Requiere: aws (con credenciales), curl y jq.

set -euo pipefail

: "${ETIQUETA:?Falta la variable ETIQUETA con el SHA desplegado}"
ALB_NOMBRE="${ALB_NOMBRE:-devops-final-alb}"
INTENTOS=10
ESPERA_SEGUNDOS=10

url=""
detalle=""

# Se ejecuta siempre al salir (exito o fallo) y deja el resultado en el resumen de
# la ejecucion. Fuera de GitHub Actions no hay GITHUB_STEP_SUMMARY y no hace nada.
escribir_resumen() {
  local codigo=$?
  [ -n "${GITHUB_STEP_SUMMARY:-}" ] || return 0

  local resultado="Correcta"
  [ "$codigo" -eq 0 ] || resultado="FALLIDA"

  {
    echo "### Prueba de humo: $resultado"
    echo ""
    echo "| Campo | Valor |"
    echo "|---|---|"
    echo "| Aplicacion | ${url:-no disponible} |"
    echo "| Etiqueta esperada | \`$ETIQUETA\` |"
    echo "| Detalle | ${detalle:-sin detalle} |"
  } >> "$GITHUB_STEP_SUMMARY"
}
trap escribir_resumen EXIT

# Reintenta hasta que la ruta responda 200. Justo despues del despliegue el ALB puede
# tardar unos segundos en considerar sanas las tareas nuevas.
esperar_200() {
  local ruta=$1
  local codigo=""
  for ((intento = 1; intento <= INTENTOS; intento++)); do
    codigo=$(curl -fsS -o /dev/null -w '%{http_code}' --max-time 5 "$url$ruta" 2>/dev/null) || true
    if [ "$codigo" = "200" ]; then
      echo "OK  $ruta -> 200"
      return 0
    fi
    echo "Intento $intento/$INTENTOS: $ruta respondio '${codigo:-sin respuesta}'; reintento en ${ESPERA_SEGUNDOS}s."
    sleep "$ESPERA_SEGUNDOS"
  done
  detalle="$ruta no respondio 200 tras $INTENTOS intentos"
  echo "::error::$url$ruta no respondio 200 tras $INTENTOS intentos."
  return 1
}

dns=$(aws elbv2 describe-load-balancers --names "$ALB_NOMBRE" \
        --query 'LoadBalancers[0].DNSName' --output text)
url="http://$dns"
echo "Aplicacion: $url"

esperar_200 "/"
esperar_200 "/api/health"

if ! version=$(curl -fsS --max-time 5 "$url/api/version" | jq -r '.version'); then
  detalle="/api/version no respondio o no devolvio JSON"
  echo "::error::$url/api/version no respondio o no devolvio JSON."
  exit 1
fi
if [ "$version" != "$ETIQUETA" ]; then
  detalle="/api/version devolvio '$version'"
  echo "::error::/api/version devolvio '$version' y se esperaba '$ETIQUETA'."
  exit 1
fi

detalle="/, /api/health y /api/version correctos"
echo "OK  /api/version -> $version"
