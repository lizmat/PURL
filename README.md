[![Actions Status](https://github.com/lizmat/PURL/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/PURL/actions) [![Actions Status](https://github.com/lizmat/PURL/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/PURL/actions) [![Actions Status](https://github.com/lizmat/PURL/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/PURL/actions)

NAME
====

PURL - Package URL specification v1.0.X

SYNOPSIS
========

```raku
use PURL;

my $purl := PURL.new("pkg:maven/org.apache.commons/io@1.3.4");
say $purl.type;       # maven
say $purl.namespace;  # org.apache.commons
say $purl.name;       # io
say $purl.version,    # 1.3.4

# Stringifies to the canonical version of the PURL
say $purl;  # pkg:maven/org.apache.commons/io@1.3.4

# If only interested in validity
if PURL("pkg:maven/org.apache.commons/io@1.3.4") {
    say "Valid Package URL";
}
```

DESCRIPTION
===========

`PURL` is distribution that provides a `PURL` class that implements the [Package URL](https://github.com/package-url/purl-spec/blob/main/PURL-SPECIFICATION.rst) specification, an attempt to standardize existing approaches to reliably identify and locate software packages.

CHECKING VALIDITY
=================

```raku
if PURL("pkg:maven/org.apache.commons/io@1.3.4") {
    say "Valid Package URL";
}
```

To just see whether a string that claims to be a Package URL is valid, one can call the class itself with that string to check: it will return either `True` or `False` (without throwing any exception).

INSTANTIATION
=============

The `PURL` object is instantiated with the `.new` method and the Package URL as the only positional argument. It will throw an error if there is some type of problem with the Package URL.

An instantiated object will stringify in the canonical version of the package URL.

ACCESSORS
=========

scheme
------

The scheme of the package specification: always 'pkg'.

type
----

The type of the package specification.

name
----

The name of the package specification.

namespace
---------

The namespace of the package specification.

version
-------

The version of the package specification.

qualifiers
----------

The qualifiers of the package specification.

subpath
-------

The subpath of tha package specification.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

