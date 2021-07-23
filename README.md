# dream-email-example

This repo illustrates how to set up a simple email integration for the
[Dream](https://aantron.github.io/dream/) web framework. I wrote it in
July of 2021, while I was at the [Recurse
Center](https://www.recurse.com/), in order to learn more about web
programming in OCaml.

<!-- I wrote a [blog -->
<!-- post](https://jsthomas.github.io/ocaml-dream-email.html) that -->
<!-- discusses this example in more detail. -->

## What does the project do?

Sending email can be quite slow. Most real web servers can't afford to
do this task in a blocking fashion because they need to respond to
requests quickly. Instead, the server adds an email task to a queue
for a background worker to process.

This project illustrates how to implement this design. The app exposes
a simple form with address/subject/text fields and allows the user to
send test emails. The project creates a single executable,
`email.exe`, that can run either as a web server or a worker. The two
processes interact using a `RabbitMQ` container to track tasks. The
worker process uses Mailgun's REST API (via `cohttp`) to send email.

## How do I set up this project?

You'll need to sign up for a mailgun account
[here](https://www.mailgun.com/). You should be able to get a free
"sandbox" account without having to pay. Once you've signed in, open
the "sending domains" tab on the main menu, you should see a sandbox
domain named something like: `sandbox<some hex id
string>.mailgun.org`. Selecting that domain should take you to a menu
with the following data:

- Your mailgun domain.
- The API key: A hexadecimal string with some dashes.
- An API base URL. Outside the EU, this looks like
  `https://api.mailgun.net/v3/<Your Domain>`.

Open `run.sh` and populate the environment variables
accordingly. Sandbox domains aren't allowed to send mail to arbitrary
addresses, so add yours as an "authorized recipient" in the mailgun
console.

Next, you'll need to make sure you have the dependencies to build the
project. I used version 4.11.1 of the compiler as well as `dream`,
`emile`, `amqp-client-lwt`, `cohttp`, `cohttp-lwt-unix`, and
`ocaml-lsp-server`. More details are in `dream-email-example.opam`.

Finally, you'll need to install docker and docker-compose. Run
`docker-compose up` to download the RabbitMQ container and view its
logs.

Start the web server by running `./run.sh server`. In a separate
shell, run `./run.sh worker` to start the worker process, which should
print a simple log that looks like this.

```
Starting Queue Worker
No new tasks, waiting.
No new tasks, waiting.
```

Finally, visit [`http://localhost:8080`](http://localhost:8080). Fill
out a message (using your "authorized recipient" email address), and
hit send. Shortly afterward in the worker shell, you should see:

```
Initiating email send to <your email here>
API Response Status: 200.
API Response body {
  "id": "<some mailgun email address here>"
  "message": "Queued. Thank you."
}.
Time to send an email: 0.67s
```

Later, you should see the message in your inbox. Notice how the worker
process helps the server avoid the latency incurred by making a
request to Mailgun API (0.67s in the example above).

## Exercises to Consider

- Mailgun also supports SMTP. How would you update the worker process to
use SMTP instead of Mailgun's API? Consider using the library
[letters](https://github.com/oxidizing/letters/) for this.
- Right now, if a request to Mailgun fails the message gets
  dropped. How would you make this system more fault tolerant?

## Feedback

If you looked through the source code for this server, let me know how
what you thought! I'm interested in adding more tutorial resources to
the OCaml ecosystem, so feel free to post a PR or issue if you have
ideas about how to make these resources better.
