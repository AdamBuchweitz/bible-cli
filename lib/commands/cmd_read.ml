open Printf
open Cmdliner
open Cmdliner.Term.Syntax
open Models
open Bible.Formatter
open Config

let ensure_dir dir =
  if not (Sys.file_exists dir) then
    Unix.mkdir dir Defaults.file_permissions

let save_chapter_verses output_dir book_name chapter_number chapter_content =
  ensure_dir (sprintf "%s/%s" output_dir book_name);
  ensure_dir (sprintf "%s/%s/%d" output_dir book_name chapter_number);
  List.iter (function
    | Verse v ->
        Out_channel.with_open_text
          (sprintf "%s/%s/%d/%02d.md" output_dir book_name chapter_number v.number)
          (fun oc -> output_string oc (format_verse v.content))
    | _ -> ()
  ) chapter_content

let save_chapter_as_file output_dir book_name chapter_number chapter_content options =
  ensure_dir (sprintf "%s/%s" output_dir book_name);
  let formatted_content = format_chapter_content chapter_content options in
  Out_channel.with_open_text
    (sprintf "%s/%s/%02d.md" output_dir book_name chapter_number)
    (fun oc -> output_string oc formatted_content)

let build_verse translation book chap verse output =
  Api.fetch_verse translation book chap verse
  |> Option.map format_verse
  |> Option.fold ~none: (sprintf "Unable to find %s %d:%d" book chap verse) ~some: Fun.id
  |> output

let build_chapter translation book chap output options chapters_mode =
  let response = Api.fetch_chapter translation book chap in
  let content = Some (format_chapter_content response.chapter.content options)
    |> Option.fold ~none: (sprintf "Unable to find %s %d" book chap) ~some: Fun.id
  in
  match output with
  | None -> print_endline content
  | Some output_dir ->
    if chapters_mode then
      save_chapter_as_file output_dir book chap response.chapter.content options
    else
      save_chapter_verses output_dir book chap response.chapter.content;
    print_endline Messages.done_message

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

let dump_book_as_verses ( built_book : chapter list ) book_name output_dir =
  List.iteri
    (fun chapter_number chapter ->
      save_chapter_verses output_dir book_name (chapter_number+1) chapter.content
    )
    built_book

let dump_book_as_chapters ( built_book : chapter list ) book_name output_dir options =
  List.iteri
    (fun chapter_number chapter ->
      save_chapter_as_file output_dir book_name (chapter_number+1) chapter.content options
    )
    built_book

let read_book translation book output options chapters_mode =
  let built_book = build_book translation book in
  match output with
  | None ->
    List.mapi (fun i chapter ->
      let content = format_chapter_content chapter.content options in
      if options.showChapters then sprintf "\n\n\n# ~~~ Chapter %d ~~~\n\n%s" (i+1) content else content ) built_book
    |> String.concat ""
    |> Str.global_replace (Str.regexp "\n\n\n") "\n\n"
    |> Str.global_replace (Str.regexp "\n\n\n") "\n\n"
    |> Str.global_replace (Str.regexp "\n\n\n") "\n\n"
    |> print_endline
  | Some output_dir ->
    if chapters_mode then
      dump_book_as_chapters built_book book output_dir options
    else
      dump_book_as_verses built_book book output_dir;
    print_endline Messages.done_message

let read_bible translation output options chapters_mode =
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
          (fun chapter_number chapter ->
            let content = format_chapter_content chapter.content options in
            if options.showChapters then sprintf "\n\n\n# ~~~ Chapter %d ~~~\n\n%s" (chapter_number+1) content else content)
          chapters)
        book_lists
      |> List.map (fun (book_name, item) -> book_name, String.concat "" item)
      |> List.map (fun (book_name, book_str) -> sprintf "\n# ~~~ The Book of %s ~~~\n\n%s" book_name book_str)
      |> String.concat "\n"
      |> print_endline
    | Some output_dir ->
      List.iter (fun (book_name, book_struct) -> 
        if chapters_mode then
          dump_book_as_chapters book_struct book_name output_dir options
        else
          dump_book_as_verses book_struct book_name output_dir) book_lists;
      print_endline Messages.done_message

let read ?format_options book chapter verse ~translation ~output ~chapters_mode =
  Option.iter (fun output_dir ->
    ensure_dir output_dir;
    printf "\nSaving output to %s.\n%!" output_dir) output;
  let default_options = { showVerses = true; showHeadings = true; showChapters = true; } in
  let options = Option.value ~default: default_options format_options in
  (* printf "\nUsing the %s translation.\n%!" translation; *)
  match book, chapter, verse with
    | None, _, _ -> read_bible translation output options chapters_mode
    | Some b, None, _ -> read_book translation b output options chapters_mode
    | Some b, Some chap, None -> build_chapter translation b chap output options chapters_mode
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
  Arg.(value & opt string Defaults.translation & info ["t"; "translation"] ~doc ~docv)

let output =
  let doc = "$(docv) is the destination directory." and docv = "OUTPUT" in
  Arg.(value & opt (some string) None & info ["o"; "output"] ~doc ~docv)

let hide_verse_numbers =
  let doc = "Hide verse numbers" in
  Arg.(value & flag & info ["hide-verse-numbers"] ~doc)

let hide_headings =
  let doc = "Hide headings" in
  Arg.(value & flag & info ["hide-headings"] ~doc)

let hide_chapters =
  let doc = "Hide chapter breaks" in
  Arg.(value & flag & info ["hide-chapters"] ~doc)

let seamless_mode =
  let doc = "Hide all extraneous markings, such as chapter breaks and verse numbers, for a seamless reading experience." in
  Arg.(value & flag & info ["seamless"] ~doc)

let chapters_mode =
  let doc = "When used with --output, save one Markdown file per chapter instead of per verse." in
  Arg.(value & flag & info ["c"; "chapters"] ~doc)

let cmd =
  Cmd.v (Cmd.info "read" ~doc:"Prints a reference") @@
  let+ translation and+ book and+ chapter and+ verse and+ output and+ hide_verse_numbers and+ hide_headings and+ hide_chapters and+ seamless_mode and+ chapters_mode in
  let options = if seamless_mode then
  {
    showVerses = false;
    showHeadings = false;
    showChapters = false;
  } else {
    showVerses = not hide_verse_numbers;
    showHeadings = not hide_headings;
    showChapters = not hide_chapters;
  } in
  read book chapter verse ~translation ~output ~format_options:options ~chapters_mode

let%expect_test "read a verse" =
  read ~translation: "BSB" (Some "John") (Some 3) (Some 16) ~output: None ~chapters_mode:false;
  [%expect{| For God so loved the world that He gave His one and only Son, that everyone who believes in Him shall not perish but have eternal life. |}]

let%expect_test "read a verse (KJV)" =
  read ~translation: "eng_kjv" (Some "John") (Some 3) (Some 16) ~output: None ~chapters_mode:false;
  [%expect{| ¶ For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life. |}]

let%expect_test "read a chapter" =
  read ~translation: "BSB" (Some "Psalms") (Some 117) None ~output: None ~chapters_mode:false;
  [%expect{|
    ### Extol Him, All You Peoples

    1

    Praise the LORD, all you nations!
    Extol Him, all you peoples!
    2

    For great is His loving devotion toward us,
    and the faithfulness of the LORD endures forever.

    Hallelujah!
    |}]

let%expect_test "No verse breaks" =
  read ~translation: "BSB" ~output: None ~format_options: { showVerses = false; showHeadings = true; showChapters = true; } (Some "Jude") None None ~chapters_mode:false;
  [%expect{|
    # ~~~ Chapter 1 ~~~

    ### A Greeting from Jude
    Jude, a servant of Jesus Christ and a brother of James,
    To those who are called, loved by God the Father, and kept in Jesus Christ:

    Mercy, peace, and love be multiplied to you.

    ### God’s Judgment on the Ungodly

    Beloved, although I made every effort to write to you about the salvation we share, I felt it necessary to write and urge you to contend earnestly for the faith entrusted once for all to the saints. For certain men have crept in among you unnoticed—ungodly ones who were designated long ago for condemnation. They turn the grace of our God into a license for immorality, and they deny our only Master and Lord, Jesus Christ.

    Although you are fully aware of this, I want to remind you that after Jesus had delivered His people out of the land of Egypt, He destroyed those who did not believe. And the angels who did not stay within their own domain but abandoned their proper dwelling—these He has kept in eternal chains under darkness, bound for judgment on that great day. In like manner, Sodom and Gomorrah and the cities around them, who indulged in sexual immorality and pursued strange flesh, are on display as an example of those who sustain the punishment of eternal fire.

    Yet in the same way these dreamers defile their bodies, reject authority, and slander glorious beings. But even the archangel Michael, when he disputed with the devil over the body of Moses, did not presume to bring a slanderous charge against him, but said, “The Lord rebuke you!” These men, however, slander what they do not understand, and like irrational animals, they will be destroyed by the things they do instinctively. Woe to them! They have traveled the path of Cain; they have rushed headlong into the error of Balaam; they have perished in Korah’s rebellion.

    These men are hidden reefs in your love feasts, shamelessly feasting with you but shepherding only themselves. They are clouds without water, carried along by the wind; fruitless trees in autumn, twice dead after being uprooted. They are wild waves of the sea, foaming up their own shame; wandering stars, for whom blackest darkness has been reserved forever.

    Enoch, the seventh from Adam, also prophesied about them:

    “Behold, the Lord is coming
    with myriads of His holy ones
    to execute judgment on everyone,
    and to convict all the ungodly
    of every ungodly act of wickedness
    and every harsh word spoken against Him by ungodly sinners.”

    These men are discontented grumblers, following after their own lusts; their mouths spew arrogance; they flatter others for their own advantage.

    ### A Call to Persevere

    But you, beloved, remember what was foretold by the apostles of our Lord Jesus Christ when they said to you, “In the last times there will be scoffers who will follow after their own ungodly desires.” These are the ones who cause divisions, who are worldly and devoid of the Spirit.

    But you, beloved, by building yourselves up in your most holy faith and praying in the Holy Spirit, keep yourselves in the love of God as you await the mercy of our Lord Jesus Christ to bring you eternal life.

    And indeed, have mercy on those who doubt; save others by snatching them from the fire; and to still others show mercy tempered with fear, hating even the clothing stained by the flesh.

    ### Doxology

    Now to Him who is able to keep you from stumbling and to present you unblemished in His glorious presence, with great joy— to the only God our Savior be glory, majesty, dominion, and authority through Jesus Christ our Lord before all time, and now, and for all eternity.
    Amen.
    |}]

let%expect_test "No headings" =
  read ~translation: "BSB" ~output: None ~format_options: { showVerses = true; showHeadings = false; showChapters = true; } (Some "Jude") None None ~chapters_mode:false;
  [%expect{|
    # ~~~ Chapter 1 ~~~

    1
    Jude, a servant of Jesus Christ and a brother of James,
    To those who are called, loved by God the Father, and kept in Jesus Christ:

    2
    Mercy, peace, and love be multiplied to you.

    3
    Beloved, although I made every effort to write to you about the salvation we share, I felt it necessary to write and urge you to contend earnestly for the faith entrusted once for all to the saints.
    4
    For certain men have crept in among you unnoticed—ungodly ones who were designated long ago for condemnation. They turn the grace of our God into a license for immorality, and they deny our only Master and Lord, Jesus Christ.

    5
    Although you are fully aware of this, I want to remind you that after Jesus had delivered His people out of the land of Egypt, He destroyed those who did not believe.
    6
    And the angels who did not stay within their own domain but abandoned their proper dwelling—these He has kept in eternal chains under darkness, bound for judgment on that great day.
    7
    In like manner, Sodom and Gomorrah and the cities around them, who indulged in sexual immorality and pursued strange flesh, are on display as an example of those who sustain the punishment of eternal fire.

    8
    Yet in the same way these dreamers defile their bodies, reject authority, and slander glorious beings.
    9
    But even the archangel Michael, when he disputed with the devil over the body of Moses, did not presume to bring a slanderous charge against him, but said, “The Lord rebuke you!”
    10
    These men, however, slander what they do not understand, and like irrational animals, they will be destroyed by the things they do instinctively.
    11
    Woe to them! They have traveled the path of Cain; they have rushed headlong into the error of Balaam; they have perished in Korah’s rebellion.

    12
    These men are hidden reefs in your love feasts, shamelessly feasting with you but shepherding only themselves. They are clouds without water, carried along by the wind; fruitless trees in autumn, twice dead after being uprooted.
    13
    They are wild waves of the sea, foaming up their own shame; wandering stars, for whom blackest darkness has been reserved forever.

    14
    Enoch, the seventh from Adam, also prophesied about them:

    “Behold, the Lord is coming
    with myriads of His holy ones
    15

    to execute judgment on everyone,
    and to convict all the ungodly
    of every ungodly act of wickedness
    and every harsh word spoken against Him by ungodly sinners.”

    16
    These men are discontented grumblers, following after their own lusts; their mouths spew arrogance; they flatter others for their own advantage.

    17
    But you, beloved, remember what was foretold by the apostles of our Lord Jesus Christ
    18
    when they said to you, “In the last times there will be scoffers who will follow after their own ungodly desires.”
    19
    These are the ones who cause divisions, who are worldly and devoid of the Spirit.

    20
    But you, beloved, by building yourselves up in your most holy faith and praying in the Holy Spirit,
    21
    keep yourselves in the love of God as you await the mercy of our Lord Jesus Christ to bring you eternal life.

    22
    And indeed, have mercy on those who doubt;
    23
    save others by snatching them from the fire; and to still others show mercy tempered with fear, hating even the clothing stained by the flesh.

    24
    Now to Him who is able to keep you from stumbling and to present you unblemished in His glorious presence, with great joy—
    25
    to the only God our Savior be glory, majesty, dominion, and authority through Jesus Christ our Lord before all time, and now, and for all eternity.
    Amen.
    |}]

let%expect_test "No chapter breaks" =
  read ~translation: "BSB" ~output: None ~format_options: { showVerses = true; showHeadings = true; showChapters = false; } (Some "Titus") None None ~chapters_mode:false;
  [%expect{|
    ### Paul’s Greeting to Titus

    1
    Paul, a servant of God and an apostle of Jesus Christ for the faith of God’s elect and their knowledge of the truth that leads to godliness,
    2
    in the hope of eternal life, which God, who cannot lie, promised before time began.
    3
    In His own time He has made His word evident in the proclamation entrusted to me by the command of God our Savior.

    4
    To Titus, my true child in our common faith:
    Grace and peace from God the Father and Christ Jesus our Savior.

    ### Appointing Elders on Crete

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

    ### Correcting False Teachers

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

    ### Teaching Sound Doctrine

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

    ### God’s Grace Brings Salvation

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

    ### Heirs of Grace

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

    ### Avoid Divisions

    9
    But avoid foolish controversies, genealogies, arguments, and quarrels about the law, because these things are pointless and worthless.

    10
    Reject a divisive man after a first and second admonition,
    11
    knowing that such a man is corrupt and sinful; he is self-condemned.

    ### Final Remarks and Greetings

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

let%expect_test "Seamless reading mode" =
  read ~translation: "BSB" ~output: None ~format_options: { showVerses = false; showHeadings = false; showChapters = false; } (Some "Titus") None None ~chapters_mode:false;
  [%expect{|
    Paul, a servant of God and an apostle of Jesus Christ for the faith of God’s elect and their knowledge of the truth that leads to godliness, in the hope of eternal life, which God, who cannot lie, promised before time began. In His own time He has made His word evident in the proclamation entrusted to me by the command of God our Savior.

    To Titus, my true child in our common faith:
    Grace and peace from God the Father and Christ Jesus our Savior.

    The reason I left you in Crete was that you would set in order what was unfinished and appoint elders in every town, as I directed you. An elder must be blameless, the husband of but one wife, having children who are believers and who are not open to accusation of indiscretion or insubordination.

    As God’s steward, an overseer must be above reproach—not self-absorbed, not quick-tempered, not given to drunkenness, not violent, not greedy for money. Instead, he must be hospitable, a lover of good, self-controlled, upright, holy, and disciplined. He must hold firmly to the faithful word as it was taught, so that he can encourage others by sound teaching and refute those who contradict it.

    For many are rebellious and full of empty talk and deception, especially those of the circumcision, who must be silenced. For the sake of dishonorable gain, they undermine entire households and teach things they should not. As one of their own prophets has said, “Cretans are always liars, evil beasts, lazy gluttons.”

    This testimony is true. Therefore rebuke them sternly, so that they will be sound in the faith and will pay no attention to Jewish myths or to the commands of men who have rejected the truth.

    To the pure, all things are pure; but to the defiled and unbelieving, nothing is pure. Indeed, both their minds and their consciences are defiled. They profess to know God, but by their actions they deny Him. They are detestable, disobedient, and unfit for any good deed. But as for you, speak the things that are consistent with sound doctrine.

    Older men are to be temperate, dignified, self-controlled, and sound in faith, love, and perseverance.

    Older women, likewise, are to be reverent in their behavior, not slanderers or addicted to much wine, but teachers of good. In this way they can train the young women to love their husbands and children, to be self-controlled, pure, managers of their households, kind, and submissive to their own husbands, so that the word of God will not be discredited.

    In the same way, urge the younger men to be self-controlled.

    In everything, show yourself to be an example by doing good works. In your teaching show integrity, dignity, and wholesome speech that is above reproach, so that anyone who opposes us will be ashamed to have nothing bad to say about us.

    Slaves are to submit to their own masters in everything, to be well-pleasing, not argumentative, not stealing from them, but showing all good faith, so that in every respect they will adorn the teaching about God our Savior.

    For the grace of God has appeared, bringing salvation to everyone. It instructs us to renounce ungodliness and worldly passions, and to live sensible, upright, and godly lives in the present age, as we await the blessed hope and glorious appearance of our great God and Savior Jesus Christ. He gave Himself for us to redeem us from all lawlessness and to purify for Himself a people for His own possession, zealous for good deeds.

    Speak these things as you encourage and rebuke with all authority. Let no one despise you. Remind the believers to submit to rulers and authorities, to be obedient and ready for every good work, to malign no one, and to be peaceable and gentle, showing full consideration to everyone.

    For at one time we too were foolish, disobedient, misled, and enslaved to all sorts of desires and pleasures—living in malice and envy, being hated and hating one another.

    But when the kindness of God our Savior and His love for mankind appeared, He saved us, not by the righteous deeds we had done, but according to His mercy, through the washing of new birth and renewal by the Holy Spirit. This is the Spirit He poured out on us abundantly through Jesus Christ our Savior, so that, having been justified by His grace, we would become heirs with the hope of eternal life. This saying is trustworthy. And I want you to emphasize these things, so that those who have believed God will take care to devote themselves to good deeds. These things are excellent and profitable for the people.

    But avoid foolish controversies, genealogies, arguments, and quarrels about the law, because these things are pointless and worthless.

    Reject a divisive man after a first and second admonition, knowing that such a man is corrupt and sinful; he is self-condemned.

    As soon as I send Artemas or Tychicus to you, make every effort to come to me at Nicopolis, because I have decided to winter there. Do your best to equip Zenas the lawyer and Apollos, so that they will have everything they need. And our people must also learn to devote themselves to good works in order to meet the pressing needs of others, so that they will not be unfruitful.

    All who are with me send you greetings.
    Greet those who love us in the faith.
    Grace be with all of you.
    |}]

let%expect_test "read a book" =
  read (Some "Obadiah") None None ~translation: "BSB" ~output: None ~chapters_mode:false;
  [%expect{|
    # ~~~ Chapter 1 ~~~

    ### The Destruction of Edom

    1
    This is the vision of Obadiah:

    This is what the Lord GOD says about Edom—

    We have heard a message from the LORD;
    an envoy has been sent among the nations
    to say, “Rise up,
    and let us go to battle against her!”—

    2

    “Behold, I will make you small among the nations;
    you will be deeply despised.
    3

    The pride of your heart has deceived you,
    O dwellers in the clefts of the rocks
    whose habitation is the heights,
    who say in your heart,
    ‘Who can bring me down to the ground?’
    4

    Though you soar like the eagle
    and make your nest among the stars,
    even from there I will bring you down,”declares the LORD.
    5

    “If thieves came to you,
    if robbers by night—
    oh, how you will be ruined—
    would they not steal only what they wanted?
    If grape gatherers came to you,
    would they not leave some gleanings?
    6

    But how Esau will be pillaged,
    his hidden treasures sought out!
    7

    All the men allied with you
    will drive you to the border;
    the men at peace with you
    will deceive and overpower you.
    Those who eat your bread
    will set a trap for you
    without your awareness of it.
    8

    In that day, declares the LORD,
    will I not destroy the wise men of Edom
    and the men of understanding
    in the mountains of Esau?
    9

    Then your mighty men, O Teman,
    will be terrified,
    so that everyone in the mountains of Esau
    will be cut down in the slaughter.

    10

    Because of the violence against your brother Jacob,
    you will be covered with shame
    and cut off forever.
    11

    On the day you stood aloof
    while strangers carried off his wealth
    and foreigners entered his gate
    and cast lots for Jerusalem,
    you were just like one of them.
    12

    But you should not gloat in that day,
    your brother’s day of misfortune,
    nor rejoice over the people of Judah
    in the day of their destruction,
    nor boast proudly
    in the day of their distress.
    13

    You should not enter the gate of My people
    in the day of their disaster,
    nor gloat over their affliction
    in the day of their disaster,
    nor loot their wealth
    in the day of their disaster.
    14

    Nor should you stand at the crossroads
    to cut off their fugitives,
    nor deliver up their survivors
    in the day of their distress.

    ### The Deliverance of Israel

    15

    For the Day of the LORD is near
    for all the nations.
    As you have done, it will be done to you;
    your recompense will return upon your own head.
    16

    For as you drank on My holy mountain,
    so all the nations will drink continually.
    They will drink and gulp it down;
    they will be as if they had never existed.
    17

    But on Mount Zion there will be deliverance,
    and it will be holy,
    and the house of Jacob
    will reclaim their possession.
    18

    Then the house of Jacob will be a blazing fire,
    and the house of Joseph a burning flame;
    but the house of Esau will be stubble—
    Jacob will set it ablaze and consume it.
    Therefore no survivor will remain
    from the house of Esau.”For the LORD has spoken.
    19

    Those from the Negev will possess the mountains of Esau;
    those from the foothills
    will possess the land of the Philistines.
    They will occupy the fields of Ephraim and Samaria,
    and Benjamin will possess Gilead.
    20

    And the exiles of this host of the Israelites
    will possess the land of the Canaanites as far as Zarephath;
    and the exiles from Jerusalem who are in Sepharad
    will possess the cities of the Negev.
    21

    The deliverers will ascend
    Mount Zion
    to rule over the mountains of Esau.

    And the kingdom will belong to the LORD.
    |}]

(* Test that chapters_mode parameter affects no stdout output *)
let%expect_test "chapters mode with stdout output (no difference expected)" =
  read ~translation: "BSB" (Some "Psalms") (Some 117) None ~output: None ~chapters_mode:true;
  [%expect{|
    ### Extol Him, All You Peoples

    1

    Praise the LORD, all you nations!
    Extol Him, all you peoples!
    2

    For great is His loving devotion toward us,
    and the faithfulness of the LORD endures forever.

    Hallelujah!
    |}]
