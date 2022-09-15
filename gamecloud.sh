#!/usr/bin/env sh

# Dependencies:
#   rclone
#   jq

# Usage:
#   gamecloud [-r|--run <name> <command>] [-c|--config <name>] [-h|--help]
# Example:
#   Configuration: gamecloud -c hl2
#   From CLI:      gamecloud -r hl2 hl2_linux -game garrysmod
#   From Steam:    gamecloud -r %command%

CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/gamecloud.json"

configure_gamecloud() {
  local game_name="$1"
  local remote_path
  local local_path

  [ -f "$CONFIG_PATH" ] || echo -n '{}' > "$CONFIG_PATH"

  echo "Configuring for $game_name"
  echo -n "Please enter the remote path (e.g. 's3:bucket/subdir'): "
  read -r remote_path
  echo -n "Please enter the local path (where save files are stored): "
  read -r local_path
  jq \
    --arg game_name "$game_name" \
    --arg remote_path "$remote_path" \
    --arg local_path "$local_path" \
    ' .[$game_name].remote_path = $remote_path | .[$game_name].local_path = $local_path' "$CONFIG_PATH" > "$CONFIG_PATH.tmp"
  mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
}

gamecloud_run() {
  local game_name="$1"
  local remote_path="$(jq -r --arg game_name "$game_name" '.[$game_name].remote_path' "$CONFIG_PATH")"
  local local_path="$(jq -r --arg game_name "$game_name" '.[$game_name].local_path' "$CONFIG_PATH")"

  [ -z "$remote_path" ] && echo "No remote path configured for $game_name" && exit 1
  [ -z "$local_path" ] && echo "No local path configured for $game_name" && exit 1

  gamecloud_pre "$game_name" "$remote_path" "$local_path"
  trap on_sigint SIGINT
  shift; "$@"
  gamecloud_post "$game_name" "$remote_path" "$local_path"
}

gamecloud_pre() {
  local game_name="$1"
  local remote_path="$2"
  local local_path="$3"

  echo "Syncing save from $remote_path/$game_name to $local_path"
  rclone sync "$remote_path/$game_name" "$local_path"
}

gamecloud_post() {
  local game_name="$1"
  local remote_path="$2"
  local local_path="$3"

  echo "Syncing save from $local_path to $remote_path/$game_name"
  rclone sync $local_path $remote_path/$game_name
}

on_sigint() {
  echo "Caught SIGINT, cleaning up and exiting"
  gamecloud_post
  exit 1
}

case "$1" in
  -c|--configure)
    shift
    configure_gamecloud "$@"
    exit 0
    ;;
  -r|--run)
    shift
    gamecloud_run "$@"
    exit 0
    ;;
  -h|--help)
    echo "Usage: gamecloud [-r|--run <name> <command>] [-c|--config <name>] [-h|--help]"
    exit 0
    ;;
  *)
    echo "Usage: gamecloud [-r|--run <name> <command>] [-c|--config <name>] [-h|--help]"
    exit 1
    ;;
esac
