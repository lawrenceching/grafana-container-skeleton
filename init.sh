#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'

function info {
  echo -e "$(date +%FT%T%z) INFO  $1"
}

function error {
  echo -e "$(date +%FT%T%z) ${RED}ERROR${NC} $1"
}

function debug {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "$(date +%FT%T%z) DEBUG $1"
  fi
}

if [[ -f /.dockerenv ]] || grep -Eq '(lxc|docker)' /proc/1/cgroup
then
    info "Scripts are running in container"
    /run.sh &
    DASHBOARD_DIR="/data/dashboards"
    IN_CONTAINER='true'
else
    info "Scripts are running in common bash environment"
    DASHBOARD_DIR="./dashboards"
    IN_CONTAINER='false'
fi

GRAFANA_BASE_URL='http://admin:admin@localhost:3000'
GRAFANA_DASHBOARD_API='/api/dashboards/db'

trap "exit 0" INT

for (( ; ; ))
do
   STATUS_CODE=$(curl -w "%{http_code}" -s -o /dev/null "$GRAFANA_BASE_URL/api/health")
   debug "$GRAFANA_BASE_URL/api/health > $STATUS_CODE"

   if [[ "$STATUS_CODE" == '200' ]]
   then
       info "Grafana is up and running"
       break;
   else
       info "Waiting Grafana to be up..."
       sleep 1
   fi
done

TIMESTAMP=$(date +%FT%T%z)

for DASHBOARD_JSON_FILE in $"$DASHBOARD_DIR/*.json"
do
  DASHBOARD_JSON_MODEL=$(cat $DASHBOARD_JSON_FILE)
  read -r -d '' BODY <<EOF
{
  "dashboard": ${DASHBOARD_JSON_MODEL},
  "folderId": 0,
  "message": "Created at ${TIMESTAMP}",
  "overwrite": false
}'
EOF

  echo $BODY > /tmp/body.json
  curl -X POST "${GRAFANA_BASE_URL}${GRAFANA_DASHBOARD_API}" \
    -H'Accept: application/json' \
    -H'Content-Type: application/json' \
    --data-binary "@/tmp/body.json"

  info "Imported dashboard $DASHBOARD_JSON_FILE"

done


if [[ "$IN_CONTAINER" == 'true' ]]; then
  while true
  do
    sleep 1
  done
fi