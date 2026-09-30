#!/usr/bin/env bash
# Luantiのsystemd管理を解除します。実行ディレクトリは問いません。
# Luanti本体、設定ファイル、ワールドは削除しません。
set -Eeuo pipefail
trap 'echo "解除に失敗しました。表示されたエラーを確認してください。" >&2' ERR

fail() { echo "$*" >&2; exit 1; }
[[ $# -eq 0 ]] || fail "使い方: bash remove_luanti_systemd.sh"
command -v systemctl >/dev/null || fail "systemctlが必要です。"
[[ -d /run/systemd/system ]] || fail "systemdが稼働していません。"
if (( EUID == 0 )); then
    admin=()
else
    command -v sudo >/dev/null || fail "sudoが必要です。"
    sudo -v
    admin=(sudo)
fi

unit_path=/etc/systemd/system/luanti.service
fragment=$(systemctl show luanti.service -p FragmentPath --value)
if [[ -n "$fragment" && "$fragment" != "$unit_path" ]]; then
    fail "別の場所のサービス設定が使われています: $fragment（変更せず終了します）"
fi
if [[ ! -e "$unit_path" && ! -L "$unit_path" ]]; then
    echo "解除対象の $unit_path はありません。"
    exit 0
fi
[[ ! -L "$unit_path" && -f "$unit_path" ]] || fail "サービス設定が通常ファイルではないため、変更せず終了します。"

#backup_path="$unit_path.bak.$(date +%Y%m%d-%H%M%S).$$"
#"${admin[@]}" cp -p -- "$unit_path" "$backup_path"
#echo "サービス設定をバックアップしました: $backup_path"

# 通常終了を待ってから、起動設定とサービスファイルを解除します。
"${admin[@]}" systemctl stop luanti.service
"${admin[@]}" systemctl disable luanti.service
"${admin[@]}" rm -- "$unit_path"
"${admin[@]}" systemctl daemon-reload
"${admin[@]}" systemctl reset-failed luanti.service 2>/dev/null || true

echo "Luantiを停止し、systemdの自動起動とサービス設定を解除しました。"
echo "Luanti本体、luanti.conf、ワールドは削除していません。"
echo "以前の起動shを使って、screenで起動できます。"
