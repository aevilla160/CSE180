#!/bin/bash

# Create certs directory if it doesn't exist
mkdir -p server/certs
mkdir -p /certs
cd certs
rm *.key
rm *.crt
rm *.req

# 1. Generate CA's private key and self-signed certificate
openssl req -x509 \
    -newkey rsa:4096 \
    -keyout ca-key.key \
    -out ca-cert.crt \
    -days 365 \
    -nodes \
    -subj "/C=US/ST=California/CN=149.28.223.185"

echo "CA's self-signed certificate"
openssl x509 -in ca-cert.crt -noout -text

# 2. Generate web server's private key and certificate signing request (CSR)
openssl req \
    -newkey rsa:4096 \
    -nodes \
    -keyout server-key.key \
    -out server-req.req \
    -subj "/C=US/ST=California/CN=killgorealpha.com"

# 3. Use CA's private key to sign web server's CSR and get back the signed certificate
openssl x509 -req \
    -in server-req.req \
    -days 60 \
    -CA ca-cert.crt \
    -CAkey ca-key.key \
    -CAcreateserial \
    -out server-cert.crt \
    -extfile server-ext.cnf

echo "Server's signed certificate"
openssl x509 -in server-cert.crt -noout -text

openssl verify -CAfile ca-cert.crt server-cert.crt

cp *.key ../server/certs/
cp *.crt ../server/certs/