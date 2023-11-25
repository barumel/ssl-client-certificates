#!/bin/bash
set -ex;

#!/bin/bash

while getopts u:p: flag
do
    case "${flag}" in
        u) user=${OPTARG};;
        p) passphrase=${OPTARG};;
    esac
done

if [ -z "$user" ];
then
  echo "The parameter -u (usename) is required!";
  exit;
fi

pass=$passphrase || mkpasswd -l 30 -d 3 -C 5 -s 3

# Generate the private key
openssl genpkey \
  -algorithm RSA \
  -pkeyopt rsa_keygen_bits:4096 \
  -aes-128-cbc \
  -out /srv/certificates/client/${user}.key \
  -passout pass:${passphrase}


# Create the csr
openssl req \
  -new \
  -config /srv/certificates/config/req.cnf \
  -key /srv/certificates/client/${user}.key \
  -out /srv/certificates/client/${user}.csr \
  -passin pass:${passphrase}

# Sign the client certificate with our CA cert.
openssl x509 \
  -req \
  -days $CERTIFICATES_SERVER_CERTIFY_DAYS \
  -in /srv/certificates/client/${user}.csr \
  -CA /srv/certificates/server/server.crt \
  -CAkey /srv/certificates/server/public.key \
  -rand_serial \
  -extensions client_extensions \
  -out /srv/certificates/client/${user}.crt \
  -passin file:/srv/certificates/server/passphrase.txt

# Create p12 as browsers need P12s (contain key and cert)
openssl pkcs12 \
  -export \
  -clcerts \
  -in /srv/certificates/client/${user}.crt \
  -inkey /srv/certificates/client/${user}.key \
  -out /srv/certificates/client/${user}.p12 \
  -passin pass:${passphrase} \
  -passout pass:${passphrase}


  echo "Cleitn Certificate created for user ${user}"
  echo "Passphrase: ${passphrase}"
