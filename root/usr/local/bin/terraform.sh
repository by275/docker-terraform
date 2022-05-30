#!/bin/bash

# TF_AUTO_RUN=1 run terraform init, plan, and apply once
# TF_AUTO_RUN=2 repeat the last step until no error occurs

log() { echo "$(date "$(printenv DATE_FORMAT)") $(printf "%-6s:" "$1") $2"; }

send_message() {
  if [ -z "${DISCORD_WEBHOOK:-}" ]; then
    return
  fi
  
  local title="$1"
  local desc="$(echo "${2}" | awk '{print}' ORS='\\n')"
  footer="at '$(cat /etc/hostname)'"

  curl -X POST $DISCORD_WEBHOOK \
    -H "Content-Type: application/json" \
    -d@- << EOF
{
  "username": "Terraform",
	"avatar_url": "https://user-images.githubusercontent.com/31406378/108641411-f9374f00-7496-11eb-82a7-0fa2a9cc5f93.png",
  "embeds": [{
    "title": "${title}",
    "color": 3066993,
    "description": "${desc}",
    "footer": {
      "text": "${footer}"
    }
  }]
}
EOF
}

TF_CMD="/usr/bin/terraform -chdir=${TF_WORK_DIR}"
TF_PLAN="$TF_DATA_DIR/tf.plan"

[ -f /config/.terraform.lock.hcl ] && \
  rm -f /config/.terraform.lock.hcl
$TF_CMD init
if [ $? -ne 0 ]; then
  log "ERROR" "terraform init FAILED"
  exit 1
fi

$TF_CMD plan -out="$TF_PLAN"
if [ $? -ne 0 ]; then
  log "ERROR" "terraform plan FAILED"
  exit 1
fi

if [ $TF_AUTO_RUN -eq 2 ]; then
  echo ""
  log "INFO" "Running terraform automation in 5s"
  sleep 5s
else
  $TF_CMD apply -auto-approve "$TF_PLAN"
  exit $?
fi

n=1
while true; do
  printf "%s[%5d] Trying... " "$(log "INFO")" $n
  RESP=$($TF_CMD apply -auto-approve "$TF_PLAN" 2>&1 |tee /dev/null; exit ${PIPESTATUS[0]})
  if [ $? -eq 0 ]; then
    send_message "New instance" "Created successfully!"
    exit 0
  fi
  # error handling
  if echo "$RESP" | grep -iq "Out of host capacity"; then
      printf "500-InternalError, Out of host capacity\n"
  else
      printf "\n\n"
      echo "$RESP"
      exit 1
  fi
  ((n++))
  sleep "$((30+$RANDOM % 30))s"
done
