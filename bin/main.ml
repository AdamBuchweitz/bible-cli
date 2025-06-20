open Cmdliner

let default =
  let doc = "A CLI for fetching and formatting the Bible" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to adam@buchweitz.life"
  ] in
  Cmd.group (Cmd.info "bible" ~version: "0.1" ~doc ~man) [
    Commands.Cmd_list.cmd;
    Commands.Cmd_read.cmd;
  ]

let () = exit (Cmdliner.Cmd.eval default)
