csrgen
======

This is a CSR generation script based on the original [CAcert script](http://wiki.cacert.org/CSRGenerator).


Usage
-----

You don't want to use it like this:

    curl -L https://raw.github.com/mss/csrgen/master/csrgen.sh | bash

It will drop the PEM encoded key (extension .key) and CSR (extension .csr) in the current directory.

You might want to specify the CSR metadata via

    ./csrgen.sh DE HH Hamburg "Silpion IT Solutions GmbH" Peter Tester

Because positional arguments are evil this is subject to change.
