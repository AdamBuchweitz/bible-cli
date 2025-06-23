# bible-cli

A command-line interface for accessing Bible content from the bible.helloao.org API. Supports listing available translations and books, reading specific vreses, chapters, or entire books, and exporting content to files.

## Usage

```bash
# List available translations
bible list translations

# List books in various sorting orders
bible list books --chronological

# Read a verse
bible read John 3 16

# Standard output fully pipable to other applications
bible read Romans 5 8 | wl-copy
bible read 1_John 1 9 | pbcopy

# Read a chapter
bible read Psalms 117

# Read a whole book
bible read Titus

# Read _the whole Bible???_
bible read

# Save output to a folder
bible read --translation eng_kjv --output ./Bible/KJV/
```

## Development

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
opam switch create --deps-only .

# Build the project
dune build

# Run the CLI
dune exec bible
dune exec bible -- list books -a
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

## License

GPL-3.0
