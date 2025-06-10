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

let read book (chapter: string option) (verse: int option) =
  let opt = match chapter with
    | None -> Some("Go fetch and print the entire book of " ^ book)
    | Some chap ->
        match verse with
          | None -> get_chapter book chap
          | Some v -> get_verse book chap v
  in
  match opt with
    | None -> printf "%s" "Unable to find that"
    | Some result -> printf "%s" result

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
  read "John" (Some "3") (Some 16);
  [%expect{|Go fetch and print John 3:16|}]

let%expect_test "read a chapter" =
  read "Psalms" (Some "1") None;
  [%expect{|Go fetch and print the chapter of Psalms 1|}]

let%expect_test "read a book" =
  read "Mark" None None;
  [%expect{|Go fetch and print the entire book of Mark|}]
