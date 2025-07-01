#!/usr/bin/env bash
# Script integral para probar los tres microservicios
# Requiere: curl, jq
set -e
AUTH_URL=${AUTH_URL:-"http://localhost:4000"}
PERFIL_URL=${PERFIL_URL:-"http://localhost:4001"}
HIST_URL=${HIST_URL:-"http://localhost:4002"}

echo "===> Autenticación"
EMAIL="demo_$(date +%s)@example.com"
PASS="1234"
curl -s -X POST "$AUTH_URL/register" -H 'Content-Type: application/json' -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" > /dev/null || true
TOKEN=$(curl -s -X POST "$AUTH_URL/login" -H 'Content-Type: application/json' -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" | jq -r .token)
echo "TOKEN=$TOKEN"
HEADER="Authorization: Bearer $TOKEN"

echo "\n===> CRUD Perfil"
PID=$(curl -s -X POST "$PERFIL_URL/profiles" -H "$HEADER" -H 'Content-Type: application/json' -d '{"full_name":"Demo","avatar_url":"https://picsum.photos/200","preferences":{"lang":"es"}}' | jq -r .id)
 echo "Perfil ID=$PID creado" 
 curl -s "$PERFIL_URL/profiles/$PID" -H "$HEADER" | jq
 curl -s -X PATCH "$PERFIL_URL/profiles/$PID" -H "$HEADER" -H 'Content-Type: application/json' -d '{"full_name":"Demo 2"}' | jq
 curl -s -X DELETE "$PERFIL_URL/profiles/$PID" -H "$HEADER" | jq

echo "\n===> Historial (GraphQL)"
QUERY='mutation{createEvent(email:"'$EMAIL'",event_type:"login",payload:{ip:"127.0.0.1"}){id event_type}}'
curl -s -X POST "$HIST_URL/graphql" -H "$HEADER" -H 'Content-Type: application/json' -d '{"query":"'$QUERY'"}' | jq
echo "\nPruebas completadas"
