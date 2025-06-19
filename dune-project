(lang dune 3.18)

(name bible)

(generate_opam_files true)

(source
 (github adambuchweitz/bible-cli))

(authors "Adam Buchweitz <adam@buchweitz.life>")

(maintainers "Adam Buchweitz <adam@buchweitz.life>")

(license "GPL-3.0-or-later")
;
; (documentation https://url/to/documentation)

(package
 (name bible)
 (synopsis "CLI tool for fetching and reading Bible content from various translations")
 (description "A command-line interface for accessing Bible content from the bible.helloao.org API. Supports listing available translations and books, reading specific chapters or entire books, and exporting content to files. Built with OCaml and provides formatted output for easy reading.")
 (depends ocaml core ppx_expect cmdliner lwt yojson cohttp-lwt-unix tls-lwt)
 (tags
  ("cli" "bible" "scripture" "api" "ocaml" "obsidian" "markdown")))
