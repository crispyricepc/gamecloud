# gamecloud

Game cloud save helper using rclone

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
gamecloud -r hl2 %command%
```
