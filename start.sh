#!/bin/bash
# start.sh - galAKUxian 起動スクリプト
# このファイルをゲーム本体と同じフォルダに置いて実行してください

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ゲーム本体を探す（title.sh以外の.shファイル）
GAME_SCRIPT=""
for f in "$SCRIPT_DIR"/*.sh; do
    base="$(basename "$f")"
    if [[ "$base" != "title.sh" && "$base" != "start.sh" ]]; then
        GAME_SCRIPT="$f"
        break
    fi
done

if [[ -z "$GAME_SCRIPT" ]]; then
    echo "ゲーム本体の .sh ファイルが見つかりません"
    echo "title.sh・start.sh 以外の .sh ファイルを同じフォルダに置いてください"
    exit 1
fi

export GAME_SCRIPT
exec bash "$SCRIPT_DIR/title.sh" "$@"
