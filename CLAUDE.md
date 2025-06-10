# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a CLI application for fetching and formatting Bible content. The project is built in OCaml using the Dune build system and provides commands to list translations/books and read Bible passages.

## Build System and Commands

- **Build**: `dune build` - Builds the project
- **Run**: `dune exec bible` - Executes the main CLI binary
- **Test**: `dune runtest` - Runs inline tests and expects tests
- **Install dependencies**: `opam install --deps-only .` - Installs OCaml dependencies

The project uses dune-project for configuration and generates the bible.opam file automatically.

## Architecture

The codebase follows a modular structure:

- `bin/main.ml` - Entry point using Cmdliner for CLI argument parsing
- `lib/` - Core library modules:
  - `api/` - HTTP client for Bible API (bible.helloao.org)
  - `commands/` - CLI command implementations (list, read)
  - `models/` - Data types and Bible book definitions
  - `formatter.ml` - Text formatting for output

## Key Dependencies

- `cmdliner` - Command-line interface construction
- `cohttp-lwt-unix` - HTTP client for API calls
- `yojson` - JSON parsing
- `core` - Jane Street's standard library replacement
- `lwt` - Asynchronous programming

## Data Flow

1. CLI commands parse arguments using Cmdliner
2. Commands call API functions that fetch JSON from bible.helloao.org
3. JSON responses are parsed into OCaml types
4. Content is formatted using the formatter module
5. Output is printed or saved to files

## Testing

The project uses ppx_expect for inline testing. Tests are defined within the source files using `let%expect_test` and can be run with `dune runtest`.

## API Integration

The application fetches data from https://bible.helloao.org/api/ with endpoints for:
- Available translations
- Books list for a translation  
- Chapter content with verses, headings, and formatting