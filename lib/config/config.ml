(* Configuration constants for the Bible CLI application *)

module ApiStrings = struct
  let base_url = "https://bible.helloao.org/api/"
  let translations_endpoint = "available_translations.json"
  let books_endpoint_suffix = "/books.json"
end

module Defaults = struct
  let translation = "BSB"
  let language = "eng"
  let file_permissions = 0o755
end

module Output = struct
  (* let chapter_file_extension = ".md" *)
  (* let verse_file_extension = ".md" *)
  (* let verse_single_format = "%s_%d_%d.md" *)
end

module Messages = struct
  (* let build_bible_prompt = "No reference provided. Build the whole Bible? (This will take a while) [y/N]: " *)
  (* let saving_output_format = "\nSaving output to %s.\n" *)
  let done_message = "Done!"
  (* let books_header_format = "The books of the Bible, sorted %sly:\n" *)
  (* let unable_to_find_verse = "Unable to find %s %d:%d" *)
  (* let unable_to_find_chapter = "Unable to find %s %d" *)
  (* let book_title_format = "\n# ~~~ The Book of %s ~~~\n%s" *)
  (* let book_chapter_format = "\n\n## Chapter %d%s" *)
end

module Sorting = struct
  let traditional = "traditional"
  let alphabetical = "alphabetical" 
  let chronological = "chronological"
end

module ListTypes = struct
  let translations = "translations"
  let books = "books"
end

module ErrorMessages = struct
  (* let invalid_list_type_format = "Invalid list type '%s'. Must be %s or %s." *)
  let unknown_content_type_format = "Unknown type: "
  let invalid_content_item = "Invalid content item"
  let missing_text_and_poem = "Object missing both text and poem fields"
end
