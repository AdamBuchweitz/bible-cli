open Cmdliner
open Cmdliner.Term.Syntax
open Printf
open Models

type list_type = Translations | Books

let list_translations () =
  let translations_list = Api.fetch_translations in
  List.filter (fun item -> item.language = "eng") translations_list
  |> List.fold_left (fun acc item -> sprintf "%s\n%10s | %s" acc item.shortName item.englishName) ""
  |> print_endline

let list_books ?(translation = "BSB") () =
  let book_list = Api.fetch_books translation in
  List.fold_left (fun acc item -> sprintf "%s\n%02d - %s" acc item.order item.name ) "" book_list
  |> print_endline

(*Constants*)
let s_translations = "translations"
let s_books = "books"

let list_type_conv =
  let parse = function
    | s when s = s_translations -> Ok Translations
    | s when s = s_books -> Ok Books
    | s -> Error (`Msg (sprintf "Invalid list type '%s'. Must be %s or %s." s s_translations s_books)) in
  let print fmt = function
    | Translations -> Format.fprintf fmt "%s" s_translations
    | Books -> Format.fprintf fmt "%s" s_books in
  Arg.conv (parse, print)

let list ?(translation = "BSB") = function
  | Books -> list_books ~translation ()
  | Translations -> list_translations ()

let arg_type = 
  let doc = sprintf "Valid arguments are: %s, %s" s_translations s_books in
  Arg.(required & pos 0 (some list_type_conv) None & info [] ~doc ~docv: "TYPE" )

let cmd =
  Cmd.v (Cmd.info "list" ~doc:"List biblical contents") @@
  let+ arg_type in
  list arg_type
