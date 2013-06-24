#!/bin/bash
# csr.sh: Certificate Signing Request Generator
# Copyright(c) 2005 Evaldo Gardenali <evaldo@gardenali.biz>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#
# ChangeLog:
# Mon May 23 00:14:37 BRT 2005 - evaldo - Initial Release
# Thu Nov  3 10:11:51 GMT 2005 - chrisc - $HOME removed so that key and csr
#                                         are generated in the current directory
# Wed Nov 16 10:42:42 GMT 2005 - chrisc - Updated to match latest version on
#                                         the CAcert wiki, rev #73
#                                         http://wiki.cacert.org/wiki/VhostTaskForce 

CSR_COUNTRY="${1:-XX}"
CSR_STATE="${2:-XX}"
CSR_LOCATION="${3:-Some City}"
CSR_COMPANY="${4:-Snake Oil, Inc.}"
CSR_FIRSTNAME="${5:-John}"
CSR_LASTNAME="${6:-Doe}"

KEYSIZE=2048

# be safe about permissions
LASTUMASK=`umask`
umask 077

# OpenSSL for HPUX needs a random file
RANDOMFILE=$HOME/.rnd

# create a config file for openssl
CONFIG=`mktemp -q /tmp/openssl.$USER.XXXXXXXX.conf`
if [ ! $? -eq 0 ]; then
    echo "Could not create temporary config file. exiting"
    exit 1
fi
trap "rm -f '$CONFIG'" EXIT

echo "Private Key and Certificate Signing Request Generator"
echo "This script was designed to suit the request format needed by"
echo "the CAcert Certificate Authority. www.CAcert.org"
echo

printf "FQDN/CommonName (eg. www.example.com): "
read COMMONNAME

echo "Type SubjectAltNames for the certificate, one per line. Enter a blank line to finish"
SAN=1        # bogus value to begin the loop
SANAMES=""   # sanitize
while [ ! "$SAN" = "" ]; do
    printf "SubjectAltName: DNS:"
    read SAN
    if [ "$SAN" = "" ]; then break; fi # end of input
    if [ "$SANAMES" = "" ]; then
        SANAMES="DNS:$SAN"
    else
        SANAMES="$SANAMES,DNS:$SAN"
    fi
done

# Config File Generation

cat <<EOF > $CONFIG
# -------------- BEGIN custom openssl.cnf -----
 HOME                    = $HOME
EOF

if [ "`uname -s`" = "HP-UX" ]; then
    echo " RANDFILE                = $RANDOMFILE" >> $CONFIG
fi

cat <<EOF >> $CONFIG
 oid_section             = new_oids
 prompt                  = no
 [ new_oids ]
 [ req ]
 default_days            = 730            # how long to certify for
 default_keyfile         = ${COMMONNAME}.key
 distinguished_name      = req_distinguished_name
 encrypt_key             = no
 string_mask = nombstr
EOF

if [ ! "$SANAMES" = "" ]; then
    echo "req_extensions = v3_req # Extensions to add to certificate request" >> $CONFIG
fi

cat <<EOF >> $CONFIG
 [ req_distinguished_name ]
 commonName              = $COMMONNAME
 countryName             = $CSR_COUNTRY
 stateOrProvinceName     = $CSR_STATE
 localityName            = $CSR_LOCATION
 organizationName        = $CSR_COMPANY
 name                    = $CSR_FIRSTNAME $CSR_LASTNAME
 surname                 = $CSR_LASTNAME
 givenName               = $CSR_FIRSTNAME
 [ v3_req ]
EOF

if [ ! "$SANAMES" = "" ]; then
    echo "subjectAltName=$SANAMES" >> $CONFIG
fi

echo "# -------------- END custom openssl.cnf -----" >> $CONFIG

echo "Running OpenSSL..."
openssl req -batch -config $CONFIG -newkey rsa:$KEYSIZE -out ${COMMONNAME}.csr

echo "Copy the following Certificate Request and paste into CAcert website to obtain a Certificate."
echo "When you receive your certificate, you 'should' name it something like ${COMMONNAME}.pem"
echo
cat ${COMMONNAME}.csr
echo
echo The Certificate request is also available in ${COMMONNAME}.csr
echo The Private Key is stored in ${COMMONNAME}.key
echo

#restore umask
umask $LASTUMASK
