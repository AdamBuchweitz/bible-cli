open Lwt.Syntax
open Cohttp_lwt_unix
open Yojson.Safe.Util
open Models

let url_base = "https://bible.helloao.org/api/"

let fetch_json url =
  let* (_, body) = Client.get (Uri.of_string url) in
  let* body_str = Cohttp_lwt.Body.to_string body in
  Yojson.Safe.from_string body_str
  |> Lwt.return

let parse_translation json =
  {
    id = json |> member "id" |> to_string;
    name = json |> member "name" |> to_string;
    website = json |> member "website" |> to_string;
    language = json |> member "language" |> to_string;
    shortName = json |> member "shortName" |> to_string;
    englishName = json |> member "englishName" |> to_string;
    numberOfBooks = json |> member "numberOfBooks" |> to_int;
  }


(* Fetch Translations *)
let fetch_translations =
  let parse_translations_response json = 
    json |> member "translations" |> to_list |> List.map parse_translation in
  fetch_json (url_base ^ "available_translations.json")
  |> Lwt.map parse_translations_response

(* Fetch List of Books *)
let fetch_books translation =
  let parse_books_response json =
    json |> member "books" |> to_list |> List.map parse_book in
  fetch_json (url_base ^ translation ^ "/books.json")
  |> Lwt.map parse_books_response
