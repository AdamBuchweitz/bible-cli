open Printf
open Lwt.Syntax
open Cohttp_lwt_unix
open Yojson.Safe.Util
open Models
open Config

let url_base = ApiStrings.base_url

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

let parse_book json =
  {
    id = json |> member "id" |> to_string;
    translationId = json |> member "translationId" |> to_string;
    name = json |> member "name" |> to_string;
    commonName = json |> member "commonName" |> to_string;
    title = json |> member "title" |> to_string;
    order = json |> member "order" |> to_int;
    numberOfChapters = json |> member "numberOfChapters" |> to_int;
    firstChapterApiLink = json |> member "firstChapterApiLink" |> to_string;
    lastChapterApiLink = json |> member "lastChapterApiLink" |> to_string;
  }

let parse_hebrew_subtitle_content json =
  match json with
  | `String s -> Text s
  | `Assoc _ as obj ->
    (match
      member "noteId" obj |> to_int_option,
      member "text" obj |> to_string_option,
      member "poem" obj |> to_int_option with
      | Some noteId, _, _ -> Note { noteId; }
      | _, Some text, Some poem -> Poem { text; poem }
      | _, Some text, None -> Poem { text; poem = 0 }
      | _, None, Some poem -> Poem { text = ""; poem }
      | _, None, None -> failwith ErrorMessages.missing_text_and_poem)
  | _ -> failwith ErrorMessages.invalid_content_item

let parse_verse_content json =
  (match json with
  | `String s -> Text s
  | `Assoc _ as obj ->
    (match
      member "lineBreak" obj |> to_bool_option,
      member "noteId" obj |> to_int_option,
      member "text" obj |> to_string_option,
      member "poem" obj |> to_int_option,
      member "heading" obj |> to_string_option with
      | _, _, _, _, Some heading -> InlineHeading { heading;}
      | Some true, _, _, _, _ -> LineBreak
      | _, Some noteId, _, _, _ -> Note { noteId; }
      | _, _, Some text, Some poem, _ -> Poem { text; poem }
      | _, _, Some text, None, _ -> Poem { text; poem = 0 }
      | _, _, None, Some poem, _ -> Poem { text = ""; poem }
      | _, _, None, None, _ -> failwith ErrorMessages.missing_text_and_poem)
  | _ -> failwith ErrorMessages.invalid_content_item : verse_content)

let parse_chapter_content json =
  let content_type = json |> member "type" |> to_string in
  match content_type with
  | "hebrew_subtitle" -> HebrewSubtitle { content = json |> member "content" |> to_list |> List.map parse_hebrew_subtitle_content }
  | "verse" -> Verse { number = json |> member "number" |> to_int; content = json |> member "content" |> to_list |> List.map parse_verse_content }
  | "heading" -> Heading { content = json |> member "content" |> to_list |> List.map to_string }
  | "line_break" -> LineBreak 
  | _ -> failwith (sprintf "%s%s" ErrorMessages.unknown_content_type_format content_type)

let parse_chapter json =
  {
    number = json |> member "number" |> to_int;
    content = json |> member "content" |> to_list |> List.map parse_chapter_content
  }

let parse_chapter_response json = 
  {
    numberOfVerses = json |> member "numberOfVerses" |> to_int;
    translation = json |> member "translation" |> parse_translation;
    chapter = json |> member "chapter" |> parse_chapter;
    book = json |> member "book" |> parse_book;
  }

(* Fetch Chapter *)
let fetch_chapter translation book chapter =
  fetch_json (sprintf "%s%s/%s/%d.json" url_base translation book chapter)
  |> Lwt.map parse_chapter_response
  |> Lwt_main.run

let fetch_verse translation book chapter verse =
  fetch_json (sprintf "%s%s/%s/%d.json" url_base translation book chapter)
  |> Lwt.map parse_chapter_response
  |> Lwt_main.run
  |> fun chapter_response -> 
      List.find_map (function
        | Verse v when v.number = verse -> Some(v.content)
        | _ -> None
      ) chapter_response.chapter.content

let fetch_translations () =
  let parse_translations_response json = 
    json |> member "translations" |> to_list |> List.map parse_translation in
  fetch_json (url_base ^ ApiStrings.translations_endpoint)
  |> Lwt.map parse_translations_response
  |> Lwt_main.run 

let fetch_books translation =
  let parse_books_response json =
    json |> member "books" |> to_list |> List.map parse_book in
  fetch_json (url_base ^ translation ^ ApiStrings.books_endpoint_suffix)
  |> Lwt.map parse_books_response
  |> Lwt_main.run 
