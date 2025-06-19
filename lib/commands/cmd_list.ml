open Printf
open Models
open Config

let sort_by_traditional_order books = 
  List.sort (fun a b -> compare a.traditional_order b.traditional_order) books

let sort_by_alphabetical_order books =
  List.sort (fun a b -> compare a.alphabetical_order b.alphabetical_order) books

let sort_by_chronological_order books =
  List.sort (fun a b -> compare a.chronological_order b.chronological_order) books

let list_translations () =
  Api.fetch_translations ()
  |> List.filter (fun item -> item.language = Defaults.language)
  |> List.fold_left (fun acc (item:translation) -> sprintf "%s\n%12s | %s" acc item.id item.englishName) ""
  |> print_endline

type sort_order = Traditional | Alphabetical | Chronological
let sort_str = function
  | Traditional -> Sorting.traditional | Alphabetical -> Sorting.alphabetical | Chronological -> Sorting.chronological

let list_books sort_order =
  let sort = match sort_order with
    | Traditional -> sort_by_traditional_order
    | Alphabetical -> sort_by_alphabetical_order
    | Chronological -> sort_by_chronological_order
  in
  bible_books
  |> sort
  |> List.fold_left (fun acc item -> sprintf "%s\n%02d | %s" acc item.traditional_order item.name) ""
  |> print_endline

type list_type = Translations | Books

let list target ~sort_order () =
  Printf.printf "The books of the Bible, sorted %sly:\n" (sort_str sort_order);
  match target with
  | Books -> list_books sort_order
  | Translations -> list_translations ()

open Cmdliner
open Cmdliner.Term.Syntax

let sort_order=
  let traditional =
    let doc = "Sort traditionally." in
    Traditional, Arg.info ["t"; "traditional"] ~doc
  in
  let alphabetical =
    let doc = "Sort alphabetically." in
    Alphabetical, Arg.info ["a"; "alphabetical"] ~doc
  in
  let chronological =
    let doc = "Sort chronologically." in
    Chronological, Arg.info ["c"; "chronological"] ~doc
  in
  Arg.(last & vflag_all [Traditional] [traditional; alphabetical; chronological])

let list_type_conv =
  let parse = function
    | s when s = ListTypes.translations -> Ok Translations
    | s when s = ListTypes.books -> Ok Books
    | s -> Error (`Msg (sprintf "Invalid list type '%s'. Must be %s or %s." s ListTypes.translations ListTypes.books)) in
  let print fmt = function
    | Translations -> Format.fprintf fmt "%s" ListTypes.translations
    | Books -> Format.fprintf fmt "%s" ListTypes.books in
  Arg.conv (parse, print)

let arg_type = 
  let doc = sprintf "Valid arguments are: %s, %s" ListTypes.translations ListTypes.books in
  Arg.(required & pos 0 (some list_type_conv) None & info [] ~doc ~docv: "TYPE" )

let cmd =
  Cmd.v (Cmd.info "list" ~doc:"List biblical contents") @@
  let+ arg_type and+ sort_order in
  list arg_type ~sort_order ()
