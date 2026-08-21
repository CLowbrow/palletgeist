# Palletgeist

A 3D puzzle game where you push boxes and exploding pallets, built with Odin,
raylib, and a portable C rules engine.

## Prerequisites

Install Odin, CMake, and a C compiler. The web build also needs Emscripten
(`emcc` and `emcmake`) and `curl`.

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

## Build for the browser

```sh
make web          # creates the browser build in build/web
make web-serve    # serves it at http://localhost:8000
make web-package  # creates build/palletgeist-web.zip for itch.io
```

The browser build preloads `assets/` and emits `index.html`, `index.js`,
`index.wasm`, `index.data`, and `odin.js`. Browsers will not run the build
correctly by opening `index.html` directly; use `make web-serve` or another
local HTTP server.

Odin distributions normally include the matching raylib/raygui WASM archives.
If they are absent (as in some package-manager installations), `make web`
downloads pinned Odin vendor archives into `build/deps` and verifies their
SHA-256 checksums.

For itch.io, create an HTML5 project and upload `build/palletgeist-web.zip`.
The zip has `index.html` at its root. A 1280×720 viewport matches the game's
native canvas; itch.io may also enable fullscreen without additional headers.
