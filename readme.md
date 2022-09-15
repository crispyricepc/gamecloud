# gamecloud

Game cloud save helper using rclone

Currently, gamecloud only does these simple steps:

1. Pull the remote save data to local
1. Run the game
1. Push the local save data to remote

The ideal behaviour would be:

1. Check if the remote save data is newer than local
  1.a. If yes, pull the remote save data to local
1. Run the game
1. Push the local save data to remote

## Installation

```sh
curl -L "https://github.com/crispyricepc/gamecloud/raw/main/gamecloud.sh" > ~/.local/bin/gamecloud
chmod +x ~/.local/bin/gamecloud
```

## Usage

```sh
gamecloud [-r|--run <name> <command>] [-c|--config <name>] [-h|--help]
```

### Examples

#### Configure

```sh
gamecloud -c hl2
```

#### Run any game

```sh
gamecloud -r hl2 hl2_linux -game garrysmod
```

#### Run from Steam

```sh
gamecloud -r %command%
```