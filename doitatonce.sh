#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .env があれば読み込み（未設定時はスクリプト内デフォルト値を使用）
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/.env"
fi

log() {
  echo "[bootstrap] $*"
}

ensure_netfilter_persistent() {
  if command -v netfilter-persistent >/dev/null 2>&1; then
    return
  fi

  log "Installing netfilter-persistent..."
  sudo apt-get update
  sudo apt-get install -y netfilter-persistent
}

ensure_swap() {
  local swapfile=/swapfile
  if swapon --noheadings --show=NAME | grep -qx "${swapfile}"; then
    log "Swap file already active at ${swapfile}."
    return
  fi

  if [[ -f ${swapfile} ]]; then
    log "Existing swap file found. Trying to activate..."
    sudo chmod 600 "${swapfile}"
    if sudo swapon "${swapfile}" 2>/dev/null; then
      log "Swap file activated."
    else
      log "Existing swap file is unusable. Recreating..."
      sudo dd if=/dev/zero of="${swapfile}" bs=1M count=2048 status=progress
      sudo chmod 600 "${swapfile}"
      sudo mkswap "${swapfile}" >/dev/null
      sudo swapon "${swapfile}"
    fi
  else
    log "Creating swap file at ${swapfile}..."
    sudo dd if=/dev/zero of="${swapfile}" bs=1M count=2048 status=progress
    sudo chmod 600 "${swapfile}"
    sudo mkswap "${swapfile}" >/dev/null
    sudo swapon "${swapfile}"
  fi

  if ! grep -q "^${swapfile} " /etc/fstab; then
    echo "${swapfile} none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
  fi

  log "Swap file ready."
}

open_port() {
  local port=$1
  # ⚠ 注意: UDP 30000 を広域に開放します
  # 子ども向けサービスでは、接続元IPを制限することを強く推奨します
  # IP制限の設定方法は firewall_setup.sh または README.md を参照してください
  if sudo iptables -C INPUT -p udp --dport "${port}" -j ACCEPT 2>/dev/null; then
    log "Firewall already allows UDP port ${port}."
  else
    log "Allowing UDP port ${port}..."
    sudo iptables -A INPUT -p udp --dport "${port}" -j ACCEPT
    sudo netfilter-persistent save >/dev/null
    sudo netfilter-persistent reload >/dev/null
  fi
}

log "Setting up swap..."
ensure_swap

ensure_netfilter_persistent

log "Configuring firewall..."
open_port "${LUANTI_PORT:-30000}"

log "Initialization complete."
