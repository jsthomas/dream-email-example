#!/bin/bash

MAILGUN_DOMAIN="populate this from the mailgun console"
export MAILGUN_API_KEY="populate this from the mailgun console"
export MAILGUN_SEND_ADDRESS="mailgun@${MAILGUN_DOMAIN}"
export MAILGUN_API_BASE="https://api.mailgun.net/v3/${MAILGUN_DOMAIN}"

dune exec ./email.exe $1
