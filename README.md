# Palletgeist

Game where you push around boxes and exploding pallets, built with

## Prerequisites

This uses submodules to pull in the game engine load them with:

```sh
git submodule update --init --recursive
```

## Build and run

```sh
make        # builds the C rules archive and build/palletgeist
make run    # builds, then opens the game
make check  # type-checks the Odin project
```
