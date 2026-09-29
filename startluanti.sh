#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/luanti"

screen -dmS luanti ./bin/luantiserver --gameid mineclonia --world worlds/world --config ./luanti.conf
#exec screen -S luanti ./bin/luantiserver --gameid mineclonia --world worlds/world --config ./luanti.conf
