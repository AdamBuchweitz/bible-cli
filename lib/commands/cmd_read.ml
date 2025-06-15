open Printf
open Cmdliner
open Cmdliner.Term.Syntax
open Models
open Bible.Formatter

let build_verse translation book chap verse output =
  Api.fetch_verse translation book chap verse
  |> Option.map format_verse
  |> Option.fold ~none: (sprintf "Unable to find %s %d:%d" book chap verse) ~some: Fun.id
  |> output

let build_chapter translation book chap =
  let response = Api.fetch_chapter translation book chap in
  Some (format_chapter_content response.chapter.content)
  |> Option.fold ~none: (sprintf "Unable to find %s %d" book chap) ~some: Fun.id
  |> print_endline

let build_book translation book =
  let spaced_book = space_to_underscore book in
  let rec get_chapter acc chapter_num =
    let response = Api.fetch_chapter translation spaced_book chapter_num in
    let acc = response.chapter :: acc in
    if response.chapter.number < response.book.numberOfChapters then
      get_chapter acc (response.chapter.number + 1)
    else
      List.rev acc
  in
  get_chapter [] 1

let ensure_dir dir =
  if not (Sys.file_exists dir) then
    Unix.mkdir dir 0o755

let dump_book_as_chapters built_book book_name output_dir =
  ensure_dir output_dir;
  ensure_dir (sprintf "%s/%s" output_dir book_name);
  List.iteri
    (fun chapter_number chapter ->
      ensure_dir (sprintf "%s/%s/%d" output_dir book_name (chapter_number+1));
      Out_channel.with_open_text (sprintf "%s/%s/%d.md" output_dir book_name (chapter_number+1)) (fun oc -> output_string oc (format_chapter_content chapter.content));
      ()
    )
    built_book

let dump_book_as_verses ( built_book : chapter list ) book_name output_dir =
  ensure_dir output_dir;
  ensure_dir (sprintf "%s/%s" output_dir book_name);
  List.iteri
    (fun chapter_number chapter ->
      ensure_dir (sprintf "%s/%s/%d" output_dir book_name (chapter_number+1));
      List.iter (function
        | Verse v ->
            Out_channel.with_open_text
              (sprintf "%s/%s/%d/%02d.md" output_dir book_name (chapter_number+1) v.number)
              (fun oc -> output_string oc (format_verse v.content))
        | _ -> ()
      ) chapter.content
    )
    built_book

let read_book translation book output =
  let built_book = build_book translation book in
  match output with
  | None ->
    List.mapi (fun i chapter -> sprintf "\n\n# ~~~ Chapter %d ~~~\n%s" (i+1) (format_chapter_content chapter.content) ) built_book
    |> String.concat ""
    |> print_endline
  | Some output_dir ->
    dump_book_as_verses built_book book output_dir;
    print_endline "Done!"

let read_bible translation output =
  printf "No reference provided. Build the whole Bible? (This will take a while) [y/N]: %!";
  let char = input_char stdin in
  let _ = input_char stdin in
  if (Char.lowercase_ascii char) = 'y' then
    let book_list = Api.fetch_books translation
      |> List.rev
      |> List.take 2 in
    let book_lists = List.map (fun book -> book.commonName, build_book translation book.id) book_list in
    match output with
    | None ->
      List.map (fun (book_name, chapters) ->
        book_name, List.mapi
          (fun chapter_number chapter -> sprintf "\n\n## Chapter %d%s" (chapter_number+1) (format_chapter_content chapter.content))
          chapters)
        book_lists
      |> List.map (fun (book_name, item) -> book_name, String.concat "" item)
      |> List.map (fun (book_name, book_str) -> sprintf "\n# ~~~ The Book of %s ~~~\n%s" book_name book_str)
      |> String.concat "\n"
      |> print_endline
    | Some output_dir ->
      List.iter (fun (book_name, book_struct) -> dump_book_as_verses book_struct book_name output_dir) book_lists;
      print_endline "Done!"

let read book chapter verse ~translation ~output =
  Option.iter (fun output -> printf "\nSaving output to %s.\n%!" output) output;
  (* printf "\nUsing the %s translation.\n%!" translation; *)
  match book, chapter, verse with
    | None, _, _ -> read_bible translation output
    | Some b, None, _ -> read_book translation b output
    | Some b, Some chap, None -> build_chapter translation b chap
    | Some b, Some chap, Some v -> build_verse translation b chap v (Option.fold
        ~none: print_endline
        ~some: (fun dir -> (fun content -> Out_channel.with_open_text (sprintf "%s/%s_%d_%d.md" dir b chap v) (fun oc -> output_string oc content)))
        output)

let book =
  let doc = "$(docv) is the book of the Bible." in
  Arg.(value & pos 0 (some string) None & info [] ~doc ~docv:"BOOK")

let chapter =
  let doc = "$(docv) is the chapter of the Bible." in
  Arg.(value & pos 1 (some int) None & info [] ~doc ~docv:"CHAPTER")

let verse =
  let doc = "$(docv) is the verse of the Bible." in
  Arg.(value & pos 2 (some int) None & info [] ~doc ~docv:"VERSE")

let translation =
  let doc = "$(docv) is which translation to use." and docv = "TRANSLATION" in
  Arg.(value & opt string "BSB" & info ["t"; "translation"] ~doc ~docv)

let output =
  let doc = "$(docv) is the destination directory." and docv = "OUTPUT" in
  Arg.(value & opt (some string) None & info ["o"; "output"] ~doc ~docv)

let cmd =
  Cmd.v (Cmd.info "read" ~doc:"Prints a reference") @@
  let+ translation and+ book and+ chapter and+ verse and+ output in
  read book chapter verse ~translation ~output

let%expect_test "read a verse" =
  read ~translation: "BSB" (Some "John") (Some 3) (Some 16) ~output: None;
  [%expect{| For God so loved the world that He gave His one and only Son, that everyone who believes in Him shall not perish but have eternal life. |}]

let%expect_test "read a verse (KJV)" =
  read ~translation: "eng_kjv" (Some "John") (Some 3) (Some 16) ~output: None;
  [%expect{| ¶ For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life. |}]

let%expect_test "read a chapter" =
  read ~translation: "BSB" (Some "Psalms") (Some 117) None ~output: None;
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
  read (Some "Titus") None None ~translation: "BSB" ~output: None;
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
     An elder must be blameless, the husband of but one wife, having children who are believers and who are not open to accusation of indiscretion or insubordination.

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
     He saved us, not by the righteous deeds we had done, but according to His mercy, through the washing of new birth and renewal by the Holy Spirit.
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
