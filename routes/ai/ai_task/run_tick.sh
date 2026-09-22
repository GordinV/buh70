#!/bin/bash
set -e

# Skripti kausta tuvastamine (alati absoluutne tee ai_task kaustani)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${SCRIPT_DIR}/state"
ENV_FILE="${SCRIPT_DIR}/.env"
LOCK_FILE="/tmp/buh70_ai_task.lock"
LOG_FILE="${STATE_DIR}/cron_tick.log"

mkdir -p "${STATE_DIR}"

# Paralleelsete käivituste lukustus flock abil
exec 200>"${LOCK_FILE}"
if ! flock -n 200; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Eelmine buh70-ai-task tikk veel kestab. Käivituse vahelejätmine." >> "${LOG_FILE}"
  exit 0
fi

# Käivitusrežiimi kontroll (interaktiivne terminal vs cron)
if [ -t 1 ]; then
  # Käsitsi käivitamine konsoolist: väljund ekraanile JA logifaili
  docker run --rm \
    --network host \
    -e TZ=Europe/Tallinn \
    -v /etc/localtime:/etc/localtime:ro \
    --env-file "${ENV_FILE}" \
    -v "${STATE_DIR}:/app/state" \
    buh70-ai-task \
    node dist/index.js "$@" 2>&1 | tee -a "${LOG_FILE}"
else
  # Cron käivitamine: vaikne režiim, kirjutamine faili cron_tick.log
  docker run --rm \
    --network host \
    -e TZ=Europe/Tallinn \
    -v /etc/localtime:/etc/localtime:ro \
    --env-file "${ENV_FILE}" \
    -v "${STATE_DIR}:/app/state" \
    buh70-ai-task \
    node dist/index.js "$@" >> "${LOG_FILE}" 2>&1
fi
