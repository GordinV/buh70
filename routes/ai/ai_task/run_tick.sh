#!/bin/bash
set -e

# Skripti tegeliku asukoha tuvastamine (lahendab ka sümbollingid / symlinks)
TARGET_SOURCE="${BASH_SOURCE[0]}"
while [ -L "$TARGET_SOURCE" ]; do
  TARGET_DIR="$(cd -P "$(dirname "$TARGET_SOURCE")" && pwd)"
  TARGET_SOURCE="$(readlink "$TARGET_SOURCE")"
  [[ $TARGET_SOURCE != /* ]] && TARGET_SOURCE="$TARGET_DIR/$TARGET_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$TARGET_SOURCE")" && pwd)"

STATE_DIR="${SCRIPT_DIR}/state"
ENV_FILE="${SCRIPT_DIR}/.env"
LOCK_FILE="/tmp/buh70_ai_task.lock"
LOG_FILE="${STATE_DIR}/cron_tick.log"

if [ ! -f "${ENV_FILE}" ]; then
  echo "VIGA: Faili .env ei leitud asukohas: ${ENV_FILE}" >&2
  exit 1
fi

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
