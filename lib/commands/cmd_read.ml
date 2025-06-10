open Printf
open Cmdliner
open Cmdliner.Term.Syntax
open Models
open Bible.Formatter

let get_chapter book chap =
  let response = Api.fetch_chapter "BSB" book chap in
  Some (format_chapter_content response.chapter.content)

let get_verse book chap verse =
  Api.fetch_verse "BSB" book chap verse
  |> Option.map format_verse

let build_book book =
  let rec get_chapter acc chapter =
    let response = Api.fetch_chapter "BSB" book chapter in
    if response.chapter.number < response.book.numberOfChapters then
      get_chapter (sprintf "%s\n\n# Chapter %d\n%s" acc response.chapter.number (format_chapter_content response.chapter.content)) (response.chapter.number + 1)
    else
      sprintf "%s\n\n# Chapter %d\n%s" acc response.chapter.number (format_chapter_content response.chapter.content)
  in
  get_chapter "" 1

let read book chapter verse =
  (match chapter, verse with
    | None, _ -> build_book book
    | Some chap, None ->
      get_chapter book chap
      |> Option.fold ~none: (sprintf "Unable to find %s %d" book chap) ~some: Fun.id
    | Some chap, Some v ->
      get_verse book chap v
      |> Option.fold ~none: (sprintf "Unable to find %s %d:%d" book chap v) ~some: Fun.id)
  |> print_endline

let book =
  let doc = "$(docv) is the book of the Bible." in
  Arg.(value & pos 0 string "-" & info [] ~doc ~docv:"BOOK")

let chapter =
  let doc = "$(docv) is the chapter of the Bible." in
  Arg.(value & pos 1 (some int) None & info [] ~doc ~docv:"CHAPTER")

let verse =
  let doc = "$(docv) is the verse of the Bible." in
  Arg.(value & pos 2 (some int) None & info [] ~doc ~docv:"VERSE")

let cmd =
  Cmd.v (Cmd.info "read" ~doc:"Prints a reference") @@
  let+ book and+ chapter and+ verse in
  read book chapter verse

let%expect_test "read a verse" =
  read "John" (Some 3) (Some 16);
  [%expect{|Go fetch and print John 3:16|}]

let%expect_test "read a chapter" =
  read "Psalms" (Some 1) None;
  [%expect{|Go fetch and print the chapter of Psalms 1|}]

let%expect_test "read a book" =
  read "Mark" None None;
  [%expect{|Go fetch and print the entire book of Mark|}]
