#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

log() {
  echo "[setup] $*"
}

clone_or_update() {
  local repo_url=$1
  local dest_dir=$2
  local ref=${3:-}

  if [[ -d "${dest_dir}/.git" ]]; then
    log "Updating ${dest_dir}..."
    if [[ -n ${ref} ]]; then
      git -C "${dest_dir}" fetch --depth 1 origin "${ref}"
    else
      git -C "${dest_dir}" fetch --depth 1 origin
    fi
    if [[ -n ${ref} ]]; then
      git -C "${dest_dir}" reset --hard "origin/${ref}"
    else
      git -C "${dest_dir}" reset --hard FETCH_HEAD
    fi
  else
    log "Cloning ${dest_dir}..."
    if [[ -n ${ref} ]]; then
      git clone -b "${ref}" --depth 1 "${repo_url}" "${dest_dir}"
    else
      git clone --depth 1 "${repo_url}" "${dest_dir}"
    fi
  fi
}

download_and_extract() {
  local url=$1
  local destination_dir=$2

  mkdir -p "${destination_dir}"
  pushd "${destination_dir}" >/dev/null
  local tmp_archive
  tmp_archive=$(mktemp)
  log "Downloading ${url}..."
  curl -fsSL "${url}" -o "${tmp_archive}"
  log "Extracting archive in ${destination_dir}..."
  unzip -qo "${tmp_archive}"
  rm -f "${tmp_archive}"
  popd >/dev/null
}

# 依存パッケージの準備
log "依存パッケージの確認..."
readarray -t packages < <(printf '%s\n' \
  g++ ninja-build cmake git libsqlite3-dev libcurl4-openssl-dev zlib1g-dev libgmp-dev \
  libjsoncpp-dev libzstd-dev libncurses-dev screen unzip)

missing_packages=()
for pkg in "${packages[@]}"; do
  if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
    missing_packages+=("${pkg}")
  fi
done

if ((${#missing_packages[@]} > 0)); then
  log "Installing missing packages: ${missing_packages[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing_packages[@]}"
else
  log "All dependencies are already installed."
fi

# LuaJITのビルド
clone_or_update "https://github.com/LuaJIT/LuaJIT" "luajit"
if [[ ! -f luajit/src/libluajit.a ]]; then
  log "Building LuaJIT..."
  make -C luajit -j"$(nproc)" amalg
else
  log "LuaJIT is already built."
fi

# Luantiの環境構築
clone_or_update "https://github.com/testersakage/luanti-jtest.git" "luanti"
log "Configuring Luanti build..."
cmake -S luanti -B luanti/build -G Ninja \
  -DBUILD_CLIENT=0 -DBUILD_SERVER=1 -DRUN_IN_PLACE=1 -DBUILD_UNITTESTS=0 -DENABLE_UTF8_SDL2_ATLAS=ON \
  -DLUA_INCLUDE_DIR="${SCRIPT_DIR}/luajit/src/" -DLUA_LIBRARY="${SCRIPT_DIR}/luajit/src/libluajit.a"
log "Building Luanti..."
ninja -C luanti/build

# luanti.confの導入
log "Luanti.confの配置..."
curl -fsSLo luanti/luanti.conf https://raw.githubusercontent.com/CoderDojo-Odawara/PaaS_Luanti_Server/main/luanti.conf

# ゲームとMODのダウンロード (オプション)
log "ゲームとMODのダウンロード (オプション)..."
clone_or_update "https://github.com/testersakage/mineclonia-jtest.git" "luanti/games/mineclonia"
download_and_extract "https://content.luanti.org/packages/mt-mods/xcompat/download/" "luanti/mods"
download_and_extract "https://content.luanti.org/packages/mt-mods/lwscratch/download/" "luanti/mods"

# worldの作成とMODの適用設定
log "worldの作成とMODの適用設定..."
if [[ ! -d luanti/worlds/world ]]; then
  timeout -s SIGINT 10 luanti/bin/luantiserver --gameid mineclonia --world luanti/worlds/world --config luanti/luanti.conf || true
fi

world_mt="luanti/worlds/world/world.mt"
if [[ -f "${world_mt}" ]]; then
  grep -q '^load_mod_xcompat = true$' "${world_mt}" || echo "load_mod_xcompat = true" >>"${world_mt}"
  grep -q '^load_mod_lwscratch = true$' "${world_mt}" || echo "load_mod_lwscratch = true" >>"${world_mt}"
fi

log "完了！ startluanti.shを実行してサーバーを起動してください。"
