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

# Create from an identity string
$purl = PURL.from-identity("PURL:auth<zef:lizmat>");

$purl = PURL.from-identity(
  "PURL:ver<0.0.5>:auth<zef:lizmat>"
  :must-be-pinned
);
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

An instantiated object will stringify in the canonical version of the package URL.

new
---

```raku
my $purl := PURL.new("pkg:maven/org.apache.commons/io@1.3.4");
```

The `PURL` object is instantiated with the `.new` method and the Package URL as the only positional argument. It will throw an error if there is some type of problem with the Package URL.

```raku
say PURL.new(:type<maven>, :name<io>, :version<3>);  # pkg:maven/io@3
```

It can also be instantiated in the ordinary named arguments way with the `.new` method.

from-identity
-------------

```raku
my $purl = PURL.from-identity("PURL:auth<zef:lizmat>");
```

Alternately a `PURL` object can be instantiated from a Raku module identity with the `.from-identity` method.

```raku
my $purl = PURL.from-identity(
  "PURL:ver<0.0.5>:auth<zef:lizmat>"
  :must-be-pinned
);
```

If the PURL reference **must** be referencing a specific version of a distribution, then the `:must-be-pinned` named argument can be specified. An error will be thrown if the specified identity is not pinned in that case.

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

OTHER METHODS
=============

VERS
----

```raku
my $purl = PURL.new("pkg:raku/zef:lizmat/PURL?vers=vers:raku/<2.0|>=1.0");
say $purl.VERS;  # vers:raku/>=1.10 | <2.0
```

Returns the associated `VERS` object if there is any (as specified by the "vers" qualifier key). Returns `Nil` if none found.

SUPPORTED TYPES
===============

The `PURL::Type` class allows for various types of introspection.

Calling the class with a string will either return the type object for the given string, or a `Failure`.

```raku
my $class = PURL::Type("bitbucket");
say "bitbucket is valid" unless $class ~~ Failure;
```

supported-names
---------------

```raku
say PURL::Type.supported-names;  # (alpm apk bitbucket bitnami...
```

The `supported-names` class method returns the names of the supported PURL types, in alphabetical order.

supported-types
---------------

```raku
say PURL::Type.supported-types;  # ((alpm) (apk) (bitbucket)...
```

The `supported-types` class method returns the type objects of the supported PURL types, in alphabetical order.

description
-----------

```raku
say PURL::Type.description("bitbucket");  # Bitbucket-based packages.
```

The `description` class method takes the name of a PURL type and returns its description.

examples
--------

```raku
.say for PURL::Type.examples("bitbucket");  # pkg:bitbucket/birke...
```

The `examples` class method takes the name of a PURL type and returns a list of valid PURL examples of that PURL type.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/PURL . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

