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
  (*footnotes: []json.Value,*)
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

let bible_books : bible_book list = [
  (* Old Testament - Pentateuch *)
  { name = "Genesis"; abbreviation = "Gen"; traditional_order = 1; alphabetical_order = 20; chronological_order = 1;  category = Pentateuch; testament = Old };
  { name = "Exodus"; abbreviation = "Exo"; traditional_order = 2; alphabetical_order = 17; chronological_order = 3;  category = Pentateuch; testament = Old };
  { name = "Leviticus"; abbreviation = "Lev"; traditional_order = 3; alphabetical_order = 26; chronological_order = 4;  category = Pentateuch; testament = Old };
  { name = "Numbers"; abbreviation = "Num"; traditional_order = 4; alphabetical_order = 32; chronological_order = 5;  category = Pentateuch; testament = Old };
  { name = "Deuteronomy"; abbreviation = "Deu"; traditional_order = 5; alphabetical_order = 15; chronological_order = 6;  category = Pentateuch; testament = Old };

  (* Old Testament - Historical Books *)
  { name = "Joshua"; abbreviation = "Jos"; traditional_order = 6; alphabetical_order = 23; chronological_order = 7;  category = HistoricalBooks; testament = Old };
  { name = "Judges"; abbreviation = "Jdg"; traditional_order = 7; alphabetical_order = 24; chronological_order = 8;  category = HistoricalBooks; testament = Old };
  { name = "Ruth"; abbreviation = "Rut"; traditional_order = 8; alphabetical_order = 35; chronological_order = 9;  category = HistoricalBooks; testament = Old };
  { name = "I Samuel"; abbreviation = "1Sa"; traditional_order = 9; alphabetical_order = 28; chronological_order = 10; category = HistoricalBooks; testament = Old };
  { name = "II Samuel"; abbreviation = "2Sa"; traditional_order = 10; alphabetical_order = 29; chronological_order = 11; category = HistoricalBooks; testament = Old };
  { name = "I Kings"; abbreviation = "1Ki"; traditional_order = 11; alphabetical_order = 27; chronological_order = 17; category = HistoricalBooks; testament = Old };
  { name = "II Kings"; abbreviation = "2Ki"; traditional_order = 12; alphabetical_order = 30; chronological_order = 18; category = HistoricalBooks; testament = Old };
  { name = "I Chronicles"; abbreviation = "1Ch"; traditional_order = 13; alphabetical_order = 25; chronological_order = 12; category = HistoricalBooks; testament = Old };
  { name = "II Chronicles"; abbreviation = "2Ch"; traditional_order = 14; alphabetical_order = 31; chronological_order = 19; category = HistoricalBooks; testament = Old };
  { name = "Ezra"; abbreviation = "Ezr"; traditional_order = 15; alphabetical_order = 18; chronological_order = 34; category = HistoricalBooks; testament = Old };
  { name = "Nehemiah"; abbreviation = "Neh"; traditional_order = 16; alphabetical_order = 33; chronological_order = 36; category = HistoricalBooks; testament = Old };
  { name = "Esther"; abbreviation = "Est"; traditional_order = 17; alphabetical_order = 16; chronological_order = 35; category = HistoricalBooks; testament = Old };

  (* Old Testament - Poetry and Wisdom *)
  { name = "Job"; abbreviation = "Job"; traditional_order = 18; alphabetical_order = 22; chronological_order = 2;  category = PoetryAndWisdom; testament = Old };
  { name = "Psalms"; abbreviation = "Psa"; traditional_order = 19; alphabetical_order = 34; chronological_order = 13; category = PoetryAndWisdom; testament = Old };
  { name = "Proverbs"; abbreviation = "Pro"; traditional_order = 20; alphabetical_order = 36; chronological_order = 15; category = PoetryAndWisdom; testament = Old };
  { name = "Ecclesiastes"; abbreviation = "Ecc"; traditional_order = 21; alphabetical_order = 14; chronological_order = 16; category = PoetryAndWisdom; testament = Old };
  { name = "Song of Songs"; abbreviation = "Son"; traditional_order = 22; alphabetical_order = 38; chronological_order = 14; category = PoetryAndWisdom; testament = Old };

  (* Old Testament - Major Prophets *)
  { name = "Isaiah"; abbreviation = "Isa"; traditional_order = 23; alphabetical_order = 21; chronological_order = 20; category = MajorProphets; testament = Old };
  { name = "Jeremiah"; abbreviation = "Jer"; traditional_order = 24; alphabetical_order = 25; chronological_order = 21; category = MajorProphets; testament = Old };
  { name = "Lamentations"; abbreviation = "Lam"; traditional_order = 25; alphabetical_order = 25; chronological_order = 22; category = MajorProphets; testament = Old };
  { name = "Ezekiel"; abbreviation = "Eze"; traditional_order = 26; alphabetical_order = 17; chronological_order = 32; category = MajorProphets; testament = Old };
  { name = "Daniel"; abbreviation = "Dan"; traditional_order = 27; alphabetical_order = 13; chronological_order = 33; category = Apocalyptic; testament = Old };

  (* Old Testament - Minor Prophets *)
  { name = "Hosea"; abbreviation = "Hos"; traditional_order = 28; alphabetical_order = 22; chronological_order = 23; category = MinorProphets; testament = Old };
  { name = "Joel"; abbreviation = "Joe"; traditional_order = 29; alphabetical_order = 24; chronological_order = 24; category = MinorProphets; testament = Old };
  { name = "Amos"; abbreviation = "Amo"; traditional_order = 30; alphabetical_order = 10; chronological_order = 25; category = MinorProphets; testament = Old };
  { name = "Obadiah"; abbreviation = "Oba"; traditional_order = 31; alphabetical_order = 33; chronological_order = 26; category = MinorProphets; testament = Old };
  { name = "Jonah"; abbreviation = "Jon"; traditional_order = 32; alphabetical_order = 23; chronological_order = 27; category = MinorProphets; testament = Old };
  { name = "Micah"; abbreviation = "Mic"; traditional_order = 33; alphabetical_order = 30; chronological_order = 28; category = MinorProphets; testament = Old };
  { name = "Nahum"; abbreviation = "Nah"; traditional_order = 34; alphabetical_order = 32; chronological_order = 29; category = MinorProphets; testament = Old };
  { name = "Habakkuk"; abbreviation = "Hab"; traditional_order = 35; alphabetical_order = 20; chronological_order = 30; category = MinorProphets; testament = Old };
  { name = "Zephaniah"; abbreviation = "Zep"; traditional_order = 36; alphabetical_order = 39; chronological_order = 31; category = MinorProphets; testament = Old };
  { name = "Haggai"; abbreviation = "Hag"; traditional_order = 37; alphabetical_order = 19; chronological_order = 37; category = MinorProphets; testament = Old };
  { name = "Zechariah"; abbreviation = "Zec"; traditional_order = 38; alphabetical_order = 40; chronological_order = 38; category = MinorProphets; testament = Old };
  { name = "Malachi"; abbreviation = "Mal"; traditional_order = 39; alphabetical_order = 29; chronological_order = 39; category = MinorProphets; testament = Old };

  (* New Testament - Gospels *)
  { name = "Matthew"; abbreviation = "Mat"; traditional_order = 40; alphabetical_order = 30; chronological_order = 40; category = Gospels; testament = New };
  { name = "Mark"; abbreviation = "Mar"; traditional_order = 41; alphabetical_order = 28; chronological_order = 41; category = Gospels; testament = New };
  { name = "Luke"; abbreviation = "Luk"; traditional_order = 42; alphabetical_order = 27; chronological_order = 42; category = Gospels; testament = New };
  { name = "John"; abbreviation = "Joh"; traditional_order = 43; alphabetical_order = 23; chronological_order = 43; category = Gospels; testament = New };

  (* New Testament - Historical Book *)
  { name = "Acts"; abbreviation = "Act"; traditional_order = 44; alphabetical_order = 9;  chronological_order = 44; category = HistoricalBooks; testament = New };

  (* New Testament - Pauline Epistles *)
  { name = "Romans"; abbreviation = "Rom"; traditional_order = 45; alphabetical_order = 36; chronological_order = 50; category = PaulinesEpistles; testament = New };
  { name = "I Corinthians"; abbreviation = "1Co"; traditional_order = 46; alphabetical_order = 26; chronological_order = 47; category = PaulinesEpistles; testament = New };
  { name = "II Corinthians"; abbreviation = "2Co"; traditional_order = 47; alphabetical_order = 31; chronological_order = 48; category = PaulinesEpistles; testament = New };
  { name = "Galatians"; abbreviation = "Gal"; traditional_order = 48; alphabetical_order = 19; chronological_order = 49; category = PaulinesEpistles; testament = New };
  { name = "Ephesians"; abbreviation = "Eph"; traditional_order = 49; alphabetical_order = 16; chronological_order = 54; category = PaulinesEpistles; testament = New };
  { name = "Philippians"; abbreviation = "Phi"; traditional_order = 50; alphabetical_order = 35; chronological_order = 55; category = PaulinesEpistles; testament = New };
  { name = "Colossians"; abbreviation = "Col"; traditional_order = 51; alphabetical_order = 13; chronological_order = 52; category = PaulinesEpistles; testament = New };
  { name = "I Thessalonians"; abbreviation = "1Th"; traditional_order = 52; alphabetical_order = 27; chronological_order = 45; category = PaulinesEpistles; testament = New };
  { name = "II Thessalonians"; abbreviation = "2Th"; traditional_order = 53; alphabetical_order = 32; chronological_order = 46; category = PaulinesEpistles; testament = New };
  { name = "I Timothy"; abbreviation = "1Ti"; traditional_order = 54; alphabetical_order = 25; chronological_order = 59; category = PaulinesEpistles; testament = New };
  { name = "II Timothy"; abbreviation = "2Ti"; traditional_order = 55; alphabetical_order = 33; chronological_order = 61; category = PaulinesEpistles; testament = New };
  { name = "Titus"; abbreviation = "Tit"; traditional_order = 56; alphabetical_order = 38; chronological_order = 60; category = PaulinesEpistles; testament = New };
  { name = "Philemon"; abbreviation = "Phm"; traditional_order = 57; alphabetical_order = 34; chronological_order = 53; category = PaulinesEpistles; testament = New };

  (* New Testament - General Epistles *)
  { name = "Hebrews"; abbreviation = "Heb"; traditional_order = 58; alphabetical_order = 21; chronological_order = 58; category = GeneralEpistles; testament = New };
  { name = "James"; abbreviation = "Jam"; traditional_order = 59; alphabetical_order = 22; chronological_order = 51; category = GeneralEpistles; testament = New };
  { name = "I Peter"; abbreviation = "1Pe"; traditional_order = 60; alphabetical_order = 28; chronological_order = 56; category = GeneralEpistles; testament = New };
  { name = "II Peter"; abbreviation = "2Pe"; traditional_order = 61; alphabetical_order = 33; chronological_order = 57; category = GeneralEpistles; testament = New };
  { name = "I John"; abbreviation = "1Jo"; traditional_order = 62; alphabetical_order = 25; chronological_order = 63; category = GeneralEpistles; testament = New };
  { name = "II John"; abbreviation = "2Jo"; traditional_order = 63; alphabetical_order = 32; chronological_order = 64; category = GeneralEpistles; testament = New };
  { name = "III John"; abbreviation = "3Jo"; traditional_order = 64; alphabetical_order = 34; chronological_order = 65; category = GeneralEpistles; testament = New };
  { name = "Jude"; abbreviation = "Jud"; traditional_order = 65; alphabetical_order = 24; chronological_order = 62; category = GeneralEpistles; testament = New };

  (* New Testament - Apocalyptic *)
  { name = "Revelation"; abbreviation = "Rev"; traditional_order = 66; alphabetical_order = 37; chronological_order = 66; category = Apocalyptic; testament = New };
]
