(** API client for fetching Bible content from bible.helloao.org *)

(** Fetch all available translations *)
val fetch_translations : unit -> Models.translation list

(** Fetch books for a specific translation *)
val fetch_books : string -> Models.book list

(** Fetch a chapter from a specific book and translation *)
val fetch_chapter : string -> string -> int -> Models.chapter_response

(** Fetch a specific verse from a chapter *)
val fetch_verse : string -> string -> int -> int -> Models.verse_content list option
