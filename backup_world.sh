#!/usr/bin/env bash
set -euo pipefail
# Luantiワールドデータ自動バックアップスクリプト
# cronで定期実行を想定
#
# 使い方:
#   ./backup_world.sh              - バックアップを実行
#   BACKUP_RETAIN_DAYS=14 ./backup_world.sh  - 14世代保持
#
# crontab設定例（毎日AM3:00にバックアップ）:
#   0 3 * * * /home/ubuntu/backup_world.sh >> /home/ubuntu/backup.log 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .env があれば読み込む（同名環境変数がある場合はそちらを優先）
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
  set +a
fi

retain_count="${BACKUP_RETAIN_DAYS:-7}"
world_dir="${WORLD_DIR:-${SCRIPT_DIR}/luanti/worlds/world}"
backup_dir="${BACKUP_DIR:-${SCRIPT_DIR}/backups}"

if [[ ! -d "${world_dir}" ]]; then
  echo "ERROR: world directory not found: ${world_dir}" >&2
  exit 1
fi

mkdir -p "${backup_dir}"

timestamp="$(date '+%Y%m%d_%H%M%S')"
backup_file="${backup_dir}/world_backup_${timestamp}.tar.gz"

tar -czf "${backup_file}" -C "$(dirname "${world_dir}")" "$(basename "${world_dir}")"

mapfile -t backup_files < <(find "${backup_dir}" -maxdepth 1 -type f -name 'world_backup_*.tar.gz' | sort)

if (( ${#backup_files[@]} > retain_count )); then
  delete_count=$(( ${#backup_files[@]} - retain_count ))
  for ((i = 0; i < delete_count; i++)); do
    rm -f "${backup_files[$i]}"
  done
fi

remaining_generations="$(find "${backup_dir}" -maxdepth 1 -type f -name 'world_backup_*.tar.gz' | wc -l | tr -d ' ')"
size_human="$(du -h "${backup_file}" | awk '{print $1}')"

printf '[%s] Backup complete: %s (size=%s, generations=%s)\n' \
  "$(date '+%Y-%m-%d %H:%M:%S')" "${backup_file}" "${size_human}" "${remaining_generations}"
