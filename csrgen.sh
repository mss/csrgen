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

CSR_ORGANIZATION="Snake Oil, Inc."
CSR_GIVENNAME="John"
CSR_SURNAME="Doe"
CSR_LOCATION="Some City"
CSR_STATE="XX"
CSR_COUNTRY="XX"

KEYSIZE=2048

usage()
{
  cat <<EOF
$( basename -- $( readlink -f $0 )) [OPTIONS] -n COMMONNAME
  -O  CSR_ORGANIZATION [Snake Oil, Inc.]
  -G  CSR_GIVENNAME    [John]
  -N  CSR_SURNAME      [Doe]
  -L  CSR_LOCATION     [Some City]
  -S  CSR_STATE        [XX]
  -C  CSR_COUNTRY      [XX]
  -k  KEYSIZE          [2048]
  -n  COMMONNAME       []
EOF
}

while getopts hO:G:N:L:S:C:k:n:a: OPT; do
  case "${OPT}" in
    h) usage; exit 0;;
    O) CSR_ORGANIZATION="${OPTARG}";;
    G) CSR_GIVENNAME="${OPTARG}";;
    N) CSR_SURNAME="${OPTARG}";;
    L) CSR_LOCATION="${OPTARG}";;
    S) CSR_STATE="${OPTARG}";;
    C) CSR_COUNTRY="${OPTARG}";;
    k) KEYSIZE="${OPTARG}";;
    n) COMMONNAME="${OPTARG}";;
    a) SANAMES="${SANAMES:+$SANAMES,}DNS:${OPTARG}";;
  esac
done
shift $(( $OPTIND - 1 ))

[ -n "${COMMONNAME}" ] || {
  printf "COMMONNAME not set\n\n"
  usage
  exit 1
}


echo "Private Key and Certificate Signing Request Generator"
echo "This script was originally designed to suit the request format needed by"
echo "the CAcert Certificate Authority. www.CAcert.org"
echo

# be safe about permissions
LASTUMASK=`umask`
umask 077

# create a config file for openssl
CONFIG=$(mktemp -q ${TMPDIR:-/tmp}/csrgen.$USER.$$.XXXXXXXX.conf)
if [ ! $? -eq 0 ]; then
    echo "Could not create temporary config file. exiting"
    exit 1
fi
trap "rm -f '$CONFIG'" EXIT

# Config File Generation
cat <<EOF >> $CONFIG
 HOME = $HOME
 oid_section = new_oids
 prompt = no
 [ new_oids ]
 [ req ]
 default_days = 730
 default_keyfile = data/${COMMONNAME}.key
 distinguished_name = req_distinguished_name
 encrypt_key = no
 string_mask = nombstr
 ${SANAMES:+req_extensions = v3_req}
 [ req_distinguished_name ]
 commonName              = $COMMONNAME
 countryName             = $CSR_COUNTRY
 stateOrProvinceName     = $CSR_STATE
 localityName            = $CSR_LOCATION
 organizationName        = $CSR_ORGANIZATION
 name                    = $CSR_GIVENNAME $CSR_SURNAME
 surname                 = $CSR_SURNAME
 givenName               = $CSR_GIVENNAME
 [ v3_req ]
 ${SANAMES:+subjectAltName = $SANAMES}
EOF

install -d data
openssl req -batch -config $CONFIG -newkey rsa:$KEYSIZE -sha256 -out data/${COMMONNAME}.csr

openssl req -in data/${COMMONNAME}.csr -noout -text
echo

echo "Copy the following Certificate Request and paste into CAcert website to obtain a Certificate."
echo "When you receive your certificate, you 'should' name it something like ${COMMONNAME}.pem"
echo
cat data/${COMMONNAME}.csr
echo
echo The Certificate request is also available in data/${COMMONNAME}.csr
echo The Private Key is stored in data/${COMMONNAME}.key
echo

#restore umask
umask $LASTUMASK
