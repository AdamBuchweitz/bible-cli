open Printf
open Cmdliner
open Cmdliner.Term.Syntax
open Models
open Bible.Formatter

let get_chapter book chap =
  let response = Api.fetch_chapter "BSB" book chap in
  Some (format_chapter_content response.chapter.content)

let get_verse book chap verse =
  Api.fetch_verse "BSB" book chap verse
  |> Option.map format_verse

let build_book book =
  printf "Build the book of %s%!\n" book;
  let rec get_chapter acc chapter =
    printf "Fetching %s %d%!\n" book chapter;
    let spaced_book = book |> space_to_underscore in
    let response = Api.fetch_chapter "BSB" spaced_book chapter in
    if response.chapter.number < response.book.numberOfChapters then
      get_chapter (sprintf "%s\n\n# Chapter %d\n%s" acc response.chapter.number (format_chapter_content response.chapter.content)) (response.chapter.number + 1)
    else
      sprintf "%s\n\n# Chapter %d\n%s" acc response.chapter.number (format_chapter_content response.chapter.content)
  in
  get_chapter "" 1

let build_bible () =
  printf "No reference provided. Build the whole Bible? (This will take a while) [y/N]: %!";
  let char = input_char stdin in
  let _ = input_char stdin in
  if (Char.lowercase_ascii char) = 'y' then
    let book_list = Api.fetch_books "BSB"
      |> List.rev
      |> List.take 2 in
    let book_strings = List.map (fun book -> build_book book.id) book_list in
    List.fold_left (fun acc book_string -> sprintf "%s\n\n%s" acc book_string) "" book_strings
  else
    ""

let read book chapter verse =
  (match book, chapter, verse with
    | None, _, _ -> build_bible ()
    | Some b, None, _ -> build_book b
    | Some b, Some chap, None ->
      get_chapter b chap
      |> Option.fold ~none: (sprintf "Unable to find %s %d" b chap) ~some: Fun.id
    | Some b, Some chap, Some v ->
      get_verse b chap v
      |> Option.fold ~none: (sprintf "Unable to find %s %d:%d" b chap v) ~some: Fun.id
  )
  |> print_endline

let book =
  let doc = "$(docv) is the book of the Bible." in
  Arg.(value & pos 0 (some string) None & info [] ~doc ~docv:"BOOK")

let chapter =
  let doc = "$(docv) is the chapter of the Bible." in
  Arg.(value & pos 1 (some int) None & info [] ~doc ~docv:"CHAPTER")

let verse =
  let doc = "$(docv) is the verse of the Bible." in
  Arg.(value & pos 2 (some int) None & info [] ~doc ~docv:"VERSE")

let cmd =
  Cmd.v (Cmd.info "read" ~doc:"Prints a reference") @@
  let+ book and+ chapter and+ verse in
  read book chapter verse

let%expect_test "read a verse" =
  read (Some "John") (Some 3) (Some 16);
  [%expect{| For God so loved the world that He gave His one and onlySon, that everyone who believes in Him shall not perish but have eternal life. |}]

let%expect_test "read a chapter" =
  read (Some "Psalms") (Some 117) None;
  [%expect{|
  ## Extol Him, All You Peoples
  1

  Praise the LORD, all you nations!
  Extol Him, all you peoples!
  2

  For great is His loving devotion toward us,
  and the faithfulness of the LORD endures forever.

  Hallelujah!
  |}]

let%expect_test "read a book" =
  read (Some "Titus") None None;
  [%expect{|
  # Chapter 1


  ## Paul’s Greeting to Titus
  1
  Paul, a servant of God and an apostle of Jesus Christ for the faith of God’s elect and their knowledge of the truth that leads to godliness,
  2
  in the hope of eternal life, which God, who cannot lie, promised before time began.
  3
  In His own time He has made His word evident in the proclamation entrusted to me by the command of God our Savior.

  4
  To Titus, my true child in our common faith:
  Grace and peace from God the Father and Christ Jesus our Savior.

  ## Appointing Elders on Crete

  5
  The reason I left you in Crete was that you would set in order what was unfinished and appoint elders in every town, as I directed you.
  6
  An elder must be blameless, the husband of but one wife,having children who are believers and who are not open to accusation of indiscretion or insubordination.

  7
  As God’s steward, an overseer must be above reproach—not self-absorbed, not quick-tempered, not given to drunkenness, not violent, not greedy for money.
  8
  Instead, he must be hospitable, a lover of good, self-controlled, upright, holy, and disciplined.
  9
  He must hold firmly to the faithful word as it was taught, so that he can encourage others by sound teaching and refute those who contradict it.

  ## Correcting False Teachers

  10
  For many are rebellious and full of empty talk and deception, especially those of the circumcision,
  11
  who must be silenced. For the sake of dishonorable gain, they undermine entire households and teach things they should not.
  12
  As one of their own prophets has said, “Cretans are always liars, evil beasts, lazy gluttons.”

  13
  This testimony is true. Therefore rebuke them sternly, so that they will be sound in the faith
  14
  and will pay no attention to Jewish myths or to the commands of men who have rejected the truth.

  15
  To the pure, all things are pure; but to the defiled and unbelieving, nothing is pure. Indeed, both their minds and their consciences are defiled.
  16
  They profess to know God, but by their actions they deny Him. They are detestable, disobedient, and unfit for any good deed.

  # Chapter 2


  ## Teaching Sound Doctrine
  1
  But as for you, speak the things that are consistent with sound doctrine.

  2
  Older men are to be temperate, dignified, self-controlled, and sound in faith, love, and perseverance.

  3
  Older women, likewise, are to be reverent in their behavior, not slanderers or addicted to much wine, but teachers of good.
  4
  In this way they can train the young women to love their husbands and children,
  5
  to be self-controlled, pure, managers of their households, kind, and submissive to their own husbands, so that the word of God will not be discredited.

  6
  In the same way, urge the younger men to be self-controlled.

  7
  In everything, show yourself to be an example by doing good works. In your teaching show integrity, dignity,
  8
  and wholesome speech that is above reproach, so that anyone who opposes us will be ashamed to have nothing bad to say about us.

  9
  Slaves are to submit to their own masters in everything, to be well-pleasing, not argumentative,
  10
  not stealing from them, but showing all good faith, so that in every respect they will adorn the teaching about God our Savior.

  ## God’s Grace Brings Salvation

  11
  For the grace of God has appeared, bringing salvation to everyone.
  12
  It instructs us to renounce ungodliness and worldly passions, and to live sensible, upright, and godly lives in the present age,
  13
  as we await the blessed hope and glorious appearance of our great God and Savior Jesus Christ.
  14
  He gave Himself for us to redeem us from all lawlessness and to purify for Himself a people for His own possession, zealous for good deeds.

  15
  Speak these things as you encourage and rebuke with all authority. Let no one despise you.

  # Chapter 3


  ## Heirs of Grace
  1
  Remind the believers to submit to rulers and authorities, to be obedient and ready for every good work,
  2
  to malign no one, and to be peaceable and gentle, showing full consideration to everyone.

  3
  For at one time we too were foolish, disobedient, misled, and enslaved to all sorts of desires and pleasures—living in malice and envy, being hated and hating one another.

  4
  But when the kindness of God our Savior and His love for mankind appeared,
  5
  He saved us, not by the righteous deeds we had done, but according to His mercy, through the washing of new birthand renewal by the Holy Spirit.
  6
  This is the Spirit He poured out on us abundantly through Jesus Christ our Savior,
  7
  so that, having been justified by His grace, we would become heirs with the hope of eternal life.
  8
  This saying is trustworthy. And I want you to emphasize these things, so that those who have believed God will take care to devote themselves to good deeds. These things are excellent and profitable for the people.

  ## Avoid Divisions

  9
  But avoid foolish controversies, genealogies, arguments, and quarrels about the law, because these things are pointless and worthless.

  10
  Reject a divisive man after a first and second admonition,
  11
  knowing that such a man is corrupt and sinful; he is self-condemned.

  ## Final Remarks and Greetings

  12
  As soon as I send Artemas or Tychicus to you, make every effort to come to me at Nicopolis, because I have decided to winter there.
  13
  Do your best to equip Zenas the lawyer and Apollos, so that they will have everything they need.
  14
  And our people must also learn to devote themselves to good works in order to meet the pressing needs of others, so that they will not be unfruitful.

  15
  All who are with me send you greetings.
  Greet those who love us in the faith.
  Grace be with all of you.
  |}]
