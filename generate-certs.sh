#!/bin/bash

# Create certs directory if it doesn't exist
mkdir -p certs
cd certs
rm *.pem

# 1. Generate CA's private key and self-signed certificate
openssl req -x509 \
    -newkey rsa:4096 \
    -keyout ca-key.key \
    -out ca-cert.cert \
    -days 365 \
    -nodes \
    -subj "/C=US/ST=California/CN=149.28.223.185"

echo "CA's self-signed certificate"
openssl x509 -in ca-cert.cert -noout -text

# 2. Generate web server's private key and certificate signing request (CSR)
openssl req \
    -newkey rsa:4096 \
    -nodes \
    -keyout server-key.key \
    -out server-req.req \
    -subj "/C=US/ST=California/CN=127.0.0.1"

# 3. Use CA's private key to sign web server's CSR and get back the signed certificate
openssl x509 -req \
    -in server-req.req \
    -days 60 \
    -CA ca-cert.cert \
    -CAkey ca-key.key \
    -CAcreateserial \
    -out server-cert.cert \
    -extfile server-ext.cnf

echo "Server's signed certificate"
openssl x509 -in server-cert.cert -noout -text

openssl verify -CAfile ca-cert.cert server-cert.cert