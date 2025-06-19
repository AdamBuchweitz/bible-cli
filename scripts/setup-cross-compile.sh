#!/bin/bash
set -e

echo "Setting up OCaml cross-compilation for Windows..."

# Check if we're on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This script is designed for Linux systems"
    exit 1
fi

# Install MinGW-w64 cross-compiler
echo "Installing MinGW-w64 cross-compiler..."
sudo apt-get update
sudo apt-get install -y gcc-mingw-w64-x86-64 gcc-mingw-w64-i686

# Add cross-compilation repositories
echo "Adding opam-cross-windows repository..."
opam repository add windows https://github.com/ocaml-cross/opam-cross-windows.git

# Update opam
opam update

# Install cross-compiler
echo "Installing OCaml Windows cross-compiler..."
opam install ocaml-windows64

# Install cross-compiled dependencies
echo "Installing cross-compiled dependencies..."
opam install -y \
    dune-windows \
    core-windows \
    cmdliner-windows \
    lwt-windows \
    yojson-windows \
    cohttp-lwt-unix-windows \
    ppx_expect-windows

echo "Cross-compilation setup complete!"
echo ""
echo "To build for Windows:"
echo "  dune build -x windows"
echo ""
echo "The Windows binary will be in:"
echo "  _build/default.windows/bin/main.exe"