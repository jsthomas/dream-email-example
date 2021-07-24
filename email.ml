open Amqp_client_lwt


let (>>=) = Lwt.bind
let (|>?) a b = Option.map b a


let rabbit_connection () =
  let%lwt connection = Connection.connect ~id:"dream" "localhost" in
  let%lwt channel = Connection.open_channel ~id:"email" Channel.no_confirm connection in
  let%lwt queue = Queue.declare channel ~arguments:[Rpc.Server.queue_argument] "email" in
  Lwt.return (channel, queue)


type email = {
  address: string;
  subject: string;
  text: string;
} [@@deriving yojson]


let send_email (e: email) =
   let open Cohttp in
   let open Cohttp_lwt_unix in

   let api_key = Sys.getenv "MAILGUN_API_KEY" in
   let sender = Sys.getenv "MAILGUN_SEND_ADDRESS" in
   let api_base = Sys.getenv "MAILGUN_API_BASE" in

   let params = [
     ("from", [sender]);
     ("to", [e.address]);
     ("subject", [e.subject]);
     ("text", [e.text])
   ] in
   let cred = `Basic ("api", api_key) in
   let uri = api_base ^ "/messages" |> Uri.of_string in
   let headers = Header.add_authorization (Header.init ()) cred in
   let start =
     Printf.printf "Initiating email send to %s.\n" e.address;
     Unix.gettimeofday () in
   let%lwt resp, rbody = Client.post_form uri ~params ~headers in
   let%lwt finish = Unix.gettimeofday () |> Lwt.return in
   let%lwt rbody_str = (Cohttp_lwt.Body.to_string rbody) in
   Printf.printf "API Response Status: %d.\n" (Code.code_of_status resp.status);
   Printf.printf "API Response body %s.\n" rbody_str;
   Printf.printf "Time to send an email: %.2fs\n" (finish -. start);
   Lwt.return ()


let handle_message (m: Message.t) =
  let text = snd m.message in
  let email =
    try
      Some (text |> Yojson.Safe.from_string |> email_of_yojson)
    with _ ->
      Printf.printf "Received invalid email record from RabbitMQ: %s" text;
      None
  in
  match email with
  | Some e -> send_email e
  | None -> Lwt.return_unit


let queue_worker () =
  Printf.printf "Starting Queue Worker\n";
  let%lwt channel, queue = rabbit_connection () in
  let rec handle () =
    Queue.get ~no_ack:true channel queue >>= fun message ->
    let task = match message with
      | Some m -> flush stdout; handle_message m
      | _ -> Printf.printf "No new tasks, waiting.\n"; flush stdout; Lwt_unix.sleep 5.
    in
    task >>= handle
  in
  handle ()


let queue_email address subject text =
  let email = {address; subject; text} in
  let text = email |> yojson_of_email |> Yojson.Safe.to_string in
  let%lwt channel, queue = rabbit_connection () in
  let%lwt _ = Queue.publish channel queue (Message.make text) in
  Lwt.return_unit


let form_post request =
  match%lwt Dream.form request with
    | `Ok ["address", address; "message", message; "subject", subject ] ->
      let parse = Emile.of_string address in
      let alert = match parse with
        | Ok _ -> Printf.sprintf "Sent an email to %s." address
        | Error _ -> Printf.sprintf "%s is not a valid email address." address
      in
      let queue_req = match parse with
        | Ok _ -> queue_email address subject message
        | Error _ -> Lwt.return_unit
    in
    queue_req >>= (fun _ ->
        Dream.html (Template.show_form ~alert request))
    | _ -> Dream.empty `Bad_Request


let web () =
  Dream.run
  @@ Dream.logger
  @@ Dream.memory_sessions
  @@ Dream.router [
    Dream.get "/"
      (fun request ->
         Dream.html (Template.show_form request));
    Dream.post "/" form_post
  ]
  @@ Dream.not_found


let () =
  match Sys.argv with
  | [| _; "server" |] -> web ()
  | [| _; "worker" |] -> Lwt_main.run @@ queue_worker ()
  | _ ->
    prerr_endline ("Usage: " ^ Sys.argv.(1) ^ " [server|worker]");
    exit 1
