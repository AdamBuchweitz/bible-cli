open Printf
open Models

type format_options = {
  showVerses: bool;
  showHeadings: bool;
  showChapters: bool;
}

let format_verse content =
  List.map (fun (v : verse_content) -> match v with
    | Text t -> t ^ " "
    | Poem p -> sprintf "\n%s%s" (String.make p.poem '\t') p.text
    | Note _ -> String.empty
    | InlineHeading h -> h.heading
    | LineBreak -> "\n"
  ) content
  |> String.concat ""

let format_hebrew_subtitle content =
  List.fold_left ((fun acc -> function
    | Text t -> acc ^ t
    | Poem p -> sprintf "%s\n%s%s" acc (String.make p.poem '\t') p.text
    | Note _ -> acc
  ) : string -> hebrew_subtitle_content -> string) "" content

let format_chapter_content chapter_content options =
  List.map
    (fun item -> (match item with
      | LineBreak -> "\n\n"
      | Heading x -> if options.showHeadings then List.fold_left (fun acc c -> sprintf "%s\n\n\n### %s\n" acc c) "" x.content else String.empty
      | HebrewSubtitle x -> sprintf "\n%s" (format_hebrew_subtitle x.content)
      | Verse x -> if options.showVerses then (sprintf "\n%d\n%s" x.number (format_verse x.content)) else format_verse x.content
    )) chapter_content
  |> String.concat ""

let space_to_underscore = String.map (fun c -> if c = ' ' then '_' else c)
