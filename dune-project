(lang dune 3.18)

(name bible)

(generate_opam_files true)

(source
 (github adambuchweitz/bible-cli))

(authors "Adam Buchweitz <adam@buchweitz.life>")

(maintainers "Adam Buchweitz <adam@buchweitz.life>")

; (license LICENSE)
;
; (documentation https://url/to/documentation)

(package
 (name bible)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml core ppx_expect)
 (tags
  ("add topics" "to describe" your project)))
