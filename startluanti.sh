#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .env があれば読み込み（未設定時はスクリプト内デフォルト値を使用）
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/.env"
fi

cd "${SCRIPT_DIR}/luanti"

exec screen -S luanti ./bin/luantiserver --gameid "${LUANTI_GAME_ID:-mineclonia}" --world "worlds/${LUANTI_WORLD_NAME:-world}" --config ./luanti.conf
