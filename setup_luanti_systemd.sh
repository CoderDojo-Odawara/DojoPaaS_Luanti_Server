#!/usr/bin/env bash
# Ubuntu/systemd用。Luantiを起動していたディレクトリで bash により実行。
# 任意で第1引数にLuantiのディレクトリを指定できます。
set -Eeuo pipefail
trap 'echo "設定に失敗しました。表示されたエラーを確認してください。" >&2' ERR

fail() { echo "$*" >&2; exit 1; }
[[ $# -le 1 ]] || fail "使い方: bash setup_luanti_systemd.sh [Luantiディレクトリ]"
command -v systemctl >/dev/null || fail "systemdが必要です。"
[[ -d /run/systemd/system ]] || fail "systemdが稼働していません。"
command -v pgrep >/dev/null || fail "pgrepが必要です（Ubuntuではprocpsパッケージ）。"
command -v systemd-analyze >/dev/null || fail "systemd-analyzeが必要です。"

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
luanti_dir=$(cd -- "${1:-$script_dir/luanti}" && pwd -P)
run_user=${SUDO_USER:-$(id -un)}
[[ "$run_user" != root ]] || fail "root以外の実行ユーザーで bash により実行してください。"
# unitファイルで特殊な意味を持つ文字を避けます。空白は利用できます。
[[ "$luanti_dir" =~ ^[a-zA-Z0-9_./\ -]+$ ]] || fail "ディレクトリ名は半角英数字、空白、_、-、.を使用してください。"
[[ -x "$luanti_dir/bin/luantiserver" ]] || fail "bin/luantiserverがありません、または実行権限がありません。"
[[ -f "$luanti_dir/luanti.conf" ]] || fail "luanti.confがありません。"
[[ -d "$luanti_dir/worlds/world" ]] || fail "worlds/worldがありません。"

if (( EUID == 0 )); then
    admin=()
else
    command -v sudo >/dev/null || fail "sudoが必要です。"
    sudo -v
    admin=(sudo)
fi

# 初回移行で、screenなどからの二重起動を防ぎます。
if ! systemctl is-active --quiet luanti.service; then
    if pgrep -u "$run_user" -x luantiserver >/dev/null; then
        fail "Luantiが起動しています。screen -r luanti で接続し、Ctrl+Cで停止してから再実行してください。"
    fi
fi

unit_tmp=$(mktemp --suffix=.service)
trap 'rm -f -- "$unit_tmp"' EXIT
cat > "$unit_tmp" <<EOF
[Unit]
Description=Luanti Server
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$run_user
WorkingDirectory="$luanti_dir"
ExecStart="$luanti_dir/bin/luantiserver" --gameid mineclonia --world "$luanti_dir/worlds/world" --config "$luanti_dir/luanti.conf"
# 異常終了時にリスタートするようにしておく
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF

systemd-analyze verify "$unit_tmp"
unit_path=/etc/systemd/system/luanti.service
if [[ -e "$unit_path" ]]; then
    backup_path="$unit_path.bak.$(date +%Y%m%d-%H%M%S).$$"
    "${admin[@]}" cp -p -- "$unit_path" "$backup_path"
    echo "既存設定をバックアップしました: $backup_path"
fi
"${admin[@]}" install -m 0644 -- "$unit_tmp" "$unit_path"
"${admin[@]}" systemctl daemon-reload
"${admin[@]}" systemctl enable luanti.service
"${admin[@]}" systemctl restart luanti.service
sleep 3
if ! systemctl is-active --quiet luanti.service; then
    "${admin[@]}" journalctl -u luanti.service -n 40 --no-pager
    fail "起動を確認できませんでした。上記ログを確認してください。"
fi
systemctl status luanti.service --no-pager
echo "自動起動を有効にしました。ログ確認: sudo journalctl -u luanti -f"
echo "以前の起動shをcron等に登録している場合は、その登録を解除してください。"
