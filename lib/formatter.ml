open Printf
open Models

let format_verse content =
  List.fold_left (fun acc -> function
    | Text t -> acc ^ t
    | Poem p -> sprintf "%s\n%s%s" acc (String.make p.poem '\t') p.text
    | LineBreak -> acc ^ "\n"
    | Note _ -> acc
  ) "" content

let format_chapter_content chapter_content =
  List.map
    (fun item -> (match item with
      | LineBreak -> ""
      | Heading x -> List.fold_left (fun acc c -> sprintf "%s\n## %s" acc c) "" x.content
      | Verse x -> sprintf "%d\n%s" x.number (format_verse x.content)
    )) chapter_content
  |> String.concat "\n"

let space_to_underscore = String.map (fun c -> if c = ' ' then '_' else c)
