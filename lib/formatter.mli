(** Text formatting utilities for Bible content *)

type format_options = {
  showVerses: bool;
  showHeadings: bool;
  showChapters: bool;
}

(** Format verse content into a readable string *)
val format_verse : Models.verse_content list -> string

(** Format chapter content into a readable string *)
val format_chapter_content : Models.chapter_content list -> format_options -> string

(** Convert spaces to underscores in strings *)
val space_to_underscore : string -> string
