#!/bin/bash

# Create certs directory if it doesn't exist
mkdir -p certs
cd certs
rm *.pem

# 1. Generate CA's private key and self-signed certificate
openssl req -x509 \
    -newkey rsa:4096 \
    -keyout ca-key.pem \
    -out ca-cert.pem \
    -days 365 \
    -nodes \
    -subj "/C=US/ST=California/CN=127.0.0.1"

echo "CA's self-signed certificate"
openssl x509 -in ca-cert.pem -noout -text

# 2. Generate web server's private key and certificate signing request (CSR)
openssl req \
    -newkey rsa:4096 \
    -nodes \
    -keyout server-key.pem \
    -out server-req.pem \
    -subj "/C=US/ST=California/CN=127.0.0.1"

# 3. Use CA's private key to sign web server's CSR and get back the signed certificate
openssl x509 -req \
    -in server-req.pem \
    -days 60 \
    -CA ca-cert.pem \
    -CAkey ca-key.pem \
    -CAcreateserial \
    -out server-cert.pem \
    -extfile server-ext.cnf

echo "Server's signed certificate"
openssl x509 -in server-cert.pem -noout -text

openssl verify -CAfile ca-cert.pem server-cert.pem
