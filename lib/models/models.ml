type translation = {
  id: string;
  name: string;
  website: string;
  language: string;
  shortName: string;
  englishName: string;
  numberOfBooks: int;
}
type book = {
  id: string;
  translationId: string;
  name: string;
  commonName: string;
  title: string;
  order: int;
  numberOfChapters: int;
  firstChapterApiLink: string;
  lastChapterApiLink: string;
}

type verse_content =
  | Text of string
  | Poem of { text: string; poem: int }
  | Note of { noteId: int }
  | LineBreak

type chapter_content = 
  | Heading of { content: string list }
  | Verse of { number: int; content: verse_content list  }
  | LineBreak

type chapter = {
  number: int;
  content: chapter_content list;
  (*footnotes: []json.Value,*)
}
type chapter_response = {
  translation: translation;
  book: book;
  chapter: chapter;
  numberOfVerses: int;
}
