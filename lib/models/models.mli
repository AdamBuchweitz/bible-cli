(** Data types and models for Bible content *)

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
  | InlineHeading of { heading: string }
  | LineBreak

type hebrew_subtitle_content =
  | Text of string
  | Poem of { text: string; poem: int }
  | Note of { noteId: int }

type chapter_content = 
  | Heading of { content: string list }
  | Verse of { number: int; content: verse_content list  }
  | HebrewSubtitle of { content: hebrew_subtitle_content list }
  | LineBreak

type chapter = {
  number: int;
  content: chapter_content list;
}

type chapter_response = {
  translation: translation;
  book: book;
  chapter: chapter;
  numberOfVerses: int;
}

type book_category =
  | Pentateuch
  | HistoricalBooks
  | PoetryAndWisdom
  | MajorProphets
  | MinorProphets
  | Gospels
  | PaulinesEpistles
  | GeneralEpistles
  | Apocalyptic

type testament =
  | Old
  | New

type bible_book = {
  name: string;
  abbreviation: string;
  traditional_order: int;
  alphabetical_order: int;
  chronological_order: int;
  category: book_category;
  testament: testament
}

val bible_books : bible_book list