#!/usr/bin/env bash
set -euo pipefail

# ファイアウォール設定ヘルパースクリプト
# 子ども向けサービスのため、ホワイトリスト方式を推奨
#
# 使い方:
#   ./firewall_setup.sh allow <IP>     - 指定IPからのUDP 30000を許可
#   ./firewall_setup.sh deny-all       - 全IP→UDP 30000を拒否（個別許可前に実行）
#   ./firewall_setup.sh show           - 現在のルールを表示

PORT=30000

usage() {
  cat <<'EOF'
使い方:
  ./firewall_setup.sh allow <IP>   指定IPからのUDP 30000を許可
  ./firewall_setup.sh deny-all     全IPからのUDP 30000を拒否
  ./firewall_setup.sh show         現在のINPUTチェーンを表示
EOF
}

allow_ip() {
  local ip=$1
  if sudo iptables -C INPUT -p udp -s "${ip}" --dport "${PORT}" -j ACCEPT 2>/dev/null; then
    echo "[firewall] 既に許可済みです: ${ip}:${PORT}/udp"
  else
    sudo iptables -I INPUT 1 -p udp -s "${ip}" --dport "${PORT}" -j ACCEPT
    echo "[firewall] 許可ルールを追加しました: ${ip}:${PORT}/udp"
  fi
}

deny_all() {
  if sudo iptables -C INPUT -p udp --dport "${PORT}" -j DROP 2>/dev/null; then
    echo "[firewall] 既に全拒否ルールが設定されています: ${PORT}/udp"
  else
    sudo iptables -A INPUT -p udp --dport "${PORT}" -j DROP
    echo "[firewall] 全拒否ルールを追加しました: ${PORT}/udp"
  fi
}

show_rules() {
  sudo iptables -L INPUT -n --line-numbers | sed -n '1,200p'
}

persist_rules() {
  if command -v netfilter-persistent >/dev/null 2>&1; then
    sudo netfilter-persistent save >/dev/null
    sudo netfilter-persistent reload >/dev/null
    echo "[firewall] ルールを永続化しました。"
  else
    echo "[firewall] 注意: netfilter-persistent 未導入のため永続化していません。"
    echo "[firewall] doitatonce.sh を先に実行するか、手動で導入してください。"
  fi
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    allow)
      if [[ $# -ne 2 ]]; then
        usage
        exit 1
      fi
      allow_ip "$2"
      persist_rules
      ;;
    deny-all)
      if [[ $# -ne 1 ]]; then
        usage
        exit 1
      fi
      deny_all
      persist_rules
      ;;
    show)
      if [[ $# -ne 1 ]]; then
        usage
        exit 1
      fi
      show_rules
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
