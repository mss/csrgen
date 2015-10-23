csrgen
======

This is a CSR generation script based on the original [CAcert script](http://wiki.cacert.org/CSRGenerator).


Usage
-----

You have to specify the metadata like this:

    ./csrgen.sh \
      -C DE \
      -S HH \
      -L Hamburg \
      -O "Silpion IT Solutions GmbH" \
      -G Peter \
      -N Tester \
      -n www.example.com \
      -a www.example.org \
      -a www.example.net

It will drop the PEM encoded key (extension .key) and CSR (extension .csr) in the data subdirectory of the current directory.
