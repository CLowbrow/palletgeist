# Palletgeist

A 3D puzzle game about pushing boxes and exploding pallets, built with Odin,
raylib, and a portable C rules engine.

## Prerequisites

Install Odin, CMake, and a C compiler.

This repository uses a submodule for the game rules engine. Load it with:

```sh
git submodule update --init --recursive
```

## Build and run

```sh
make        # builds the C rules archive and build/palletgeist
make run    # builds, then opens the game
make check  # type-checks the Odin project
```

The build output includes the runtime assets under `build/assets`. Keep that
directory beside the executable when copying or distributing the game.
