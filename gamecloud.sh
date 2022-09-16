#!/usr/bin/env sh

# Dependencies:
#   rclone
#   jq
#   zenity

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

  echo -n "Do you want to upload your save files now? [y/N]: "
  read -r upload; [ "$upload" = "y" ] &&\
    gamecloud_upload "$game_name" "$remote_path" "$local_path"
}

gamecloud_run() {
  local game_name="$1"
  local remote_path="$(jq -r --arg game_name "$game_name" '.[$game_name].remote_path' "$CONFIG_PATH")"
  local local_path="$(jq -r --arg game_name "$game_name" '.[$game_name].local_path' "$CONFIG_PATH")"

  [ -z "$remote_path" ] && echo "No remote path configured for $game_name" && exit 1
  [ -z "$local_path" ] && echo "No local path configured for $game_name" && exit 1

  local local_mtime=$(find "$local_path" -type f -printf "%T@\n" | sort -n | tail -n1 | cut -d . -f 1)
  local local_hostname=$(hostnamectl hostname)
  local remote_mtime
  local remote_hostname
  read remote_mtime remote_hostname < <(echo $(rclone cat "$remote_path/$game_name.gamecloud.json" | jq -r '.mtime, .hostname'))

  local conflict_prompt="Cloud save conflict: The locally stored save data is newer than the cloud.\n\n"\
"Local save time: $(date -d @$local_mtime)\n\tMachine: $local_hostname\n"\
"Cloud save time: $(date -d @$remote_mtime)\n\tMachine: $remote_hostname\n\n"\
"Would you like to use your locally saved data (deleting data stored on the cloud)?"

  if [ "$local_mtime" -gt "$remote_mtime" ] && zenity --question --title="Cloud save conflict" --text="$conflict_prompt"; then
    gamecloud_upload "$game_name" "$remote_path" "$local_path"
  else
    gamecloud_download "$game_name" "$remote_path" "$local_path"
  fi

  trap on_sigint SIGINT
  shift; "$@"
  gamecloud_upload "$game_name" "$remote_path" "$local_path"
}

gamecloud_download() {
  local game_name="$1"
  local remote_path="$2"
  local local_path="$3"

  zenity --notification --text="Syncing save from $remote_path/$game_name to $local_path"
  rclone sync "$remote_path/$game_name" "$local_path"
}

gamecloud_upload() {
  local game_name="$1"
  local remote_path="$2"
  local local_path="$3"

  zenity --notification --text="Syncing save from $local_path to $remote_path/$game_name"
  jq -n\
    --arg hostname "$(hostnamectl hostname)" \
    --arg mtime "$(find "$local_path" -type f -printf "%T@\n" | sort -n | tail -n1 | cut -d . -f 1)" \
    '{"hostname": $hostname, "mtime": $mtime}' | rclone rcat "$remote_path/$game_name.gamecloud.json"
  rclone sync $local_path $remote_path/$game_name
}

on_sigint() {
  echo "Caught SIGINT, cleaning up and exiting"
  gamecloud_upload
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
