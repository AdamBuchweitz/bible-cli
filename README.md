# bible-cli

A command-line interface for accessing Bible content from the bible.helloao.org API. Supports listing available translations and books, reading specific chapters or entire books, and exporting content to files.

## Installation

### Prerequisites

- OCaml (>= 4.14)
- OPAM (>= 2.1)
- Dune (>= 3.18)

### Linux and macOS

```bash
# Clone the repository
git clone https://github.com/adambuchweitz/bible-cli.git
cd bible-cli

# Install dependencies
opam install --deps-only .

# Build the project
dune build

# Run the CLI
dune exec bible
```

### Windows

#### Method 1: Native Windows (Recommended)

1. **Install OPAM for Windows**:
   ```powershell
   # Run in PowerShell or Command Prompt
   Invoke-Expression "& { $(Invoke-RestMethod https://opam.ocaml.org/install.ps1) }"
   ```

2. **Initialize OPAM**:
   ```cmd
   opam init
   # Select option 1 to let OPAM manage Unix support infrastructure
   ```

3. **Activate the OPAM environment**:
   ```cmd
   # Follow the instructions shown after opam init
   eval $(opam env)
   ```

4. **Clone and build the project**:
   ```cmd
   git clone https://github.com/adambuchweitz/bible-cli.git
   cd bible-cli
   opam install --deps-only .
   dune build
   ```

5. **Run the CLI**:
   ```cmd
   dune exec bible
   ```

#### Method 2: Windows Subsystem for Linux (WSL2)

1. **Install WSL2** with Ubuntu from the Microsoft Store
2. **Open Ubuntu terminal** and update packages:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Install OPAM**:
   ```bash
   bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
   ```

4. **Initialize OPAM**:
   ```bash
   opam init
   eval $(opam env)
   ```

5. **Clone and build the project**:
   ```bash
   git clone https://github.com/adambuchweitz/bible-cli.git
   cd bible-cli
   opam install --deps-only .
   dune build
   dune exec bible
   ```

## Building from Source

### Windows-Specific Notes

- **OPAM 2.2** provides native Windows support
- The project uses **mingw-w64** port (GCC-based) which is well-supported
- All dependencies are available through OPAM on Windows
- No additional Windows-specific configuration required

### Development Dependencies

```bash
# Install development tools (optional)
opam install ocaml-lsp-server odoc ocamlformat
```

## Usage

```bash
# List available translations
dune exec bible -- list translations

# List books in a translation
dune exec bible -- list books --translation ESV

# Read a chapter
dune exec bible -- read --translation ESV --book Genesis --chapter 1

# Save output to file
dune exec bible -- read --translation ESV --book Genesis --chapter 1 --output genesis1.md
```

## License

[License information]