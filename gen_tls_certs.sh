#!/bin/bash

mkdir certs

openssl req -newkey rsa:2048 -nodes -keyout certs/serverkey.pem -out certs/server.csr

openssl x509 -req -days 365 -in certs/server.csr -signkey certs/serverkey.pem -out certs/servercert.pem

openssl req -new -x509 -nodes -days 365 -keyout certs/cakey.pem -out certs/cacert.pem

cat certs/servercert.pem certs/cacert.pem > certs/server_chain.pem

ln -s /etc/ssl/certs/ca-certificates.crt certs/ca-certificates.crt
