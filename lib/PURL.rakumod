use Identity::Utils:ver<0.0.24+>:auth<zef:lizmat> <
  api auth is-pinned short-name ver
>;
use JSON::Fast:ver<0.19+>:auth<cpan:TIMOTIMO>;
use PURL::Type:ver<0.0.5>:auth<zef:lizmat>;

#- helper subroutines ----------------------------------------------------------

# Is a given string a valid identifier
my sub is-identifier($_) {
    .contains: /^ <[a..z A..Z]> <[a..z A..Z 0..9 . _ -]>+ $/
}

# Trim leading and trailing
my sub trim-slashes(Str:D $_) { .subst(/^ '/'+ /).subst(/ '/'+ $/) }

# Quick-and-dirty percent-decode a string
my sub encode(Str:D $_) {
  .subst:
    / <-[a..z A..Z 0..9 _ ~ . : = / % -]> /,
    '%' ~ *.ord.fmt('%02x'),
    :global
}

# Quick-and-dirty percent-decode a string
my sub decode(Str:D $_) {
  .subst:
    / '%' <[0..9 a..f A..F]> ** 2 /,
    *.substr(1).parse-base(16).chr,
    :global
}

#- PURL ------------------------------------------------------------------------
class PURL:ver<0.0.5>:auth<zef:lizmat> {
    has Str $.scheme is required;
    has Str $.type   is required;
    has Str $.name   is required;
    has Str $.namespace;
    has Str $.version;
    has Str %.qualifiers;

    # Kept as an array as to be able to filter out components
    # when canonicalizing.
    has Str @.subpath;

    # Create an argument hash for the given Package URL
    method !hashify(Str:D $spec) {
        my %args;
        my Str $remainder;

        # subpath
        with $spec.rindex("#") -> $index {
            %args<subpath> = $spec.substr($index + 1).split("/").map({
                if $_ {
                    my $decode = decode($_);
                    $decode unless $decode eq '.' | '..';
                }
            }).List;

            $remainder = $spec.substr(0, $index);
        }
        else {
            $remainder = $spec;
        }

        # qualifier
        with $remainder.rindex("?") -> $index {
            my %seen;
            %args<qualifiers> = $remainder.substr($index + 1).split('&').map({
                my ($key, $value) = .split("=", 2);
                die "Invalid qualifier key: $key" unless is-identifier($key);

                if $value {
                    $value = decode $value;
                    $key.lc => $key eq "checksum" | "checksums"
                      ?? ($value = $value.split(",").List)
                      !! $value
                }
            }).Map;

            $remainder = $remainder.substr(0, $index);
        }

        # scheme
        with $remainder.index(":") -> $index {
            %args<scheme> := $remainder.substr(0,$index);

            die "Scheme must be 'pkg'" unless %args<scheme> eq 'pkg';
            $remainder = $remainder.substr($index + 1);
        }
        else {
            die "Must have a scheme specified";
        }

        $remainder = trim-slashes $remainder;

        # type
        with $remainder.index("/") -> $index {
            my $type := $remainder.substr(0,$index);
            die "Invalid type: $type" unless is-identifier($type);

            %args<type> = $type.lc;  # canonicalize now for later checks

            $remainder = $remainder.substr($index + 1);
        }
        else {
            die "Must have a type specified";
        }

        # version
        with $remainder.rindex("@") -> $index {
            %args<version> = decode $remainder.substr($index + 1);

            $remainder = $remainder.substr(0, $index);
        }

        # name
        my $name;
        with $remainder.rindex("/") -> $index {
            $name = $remainder.substr($index + 1);

            $remainder = $remainder.substr(0, $index);
        }
        elsif $remainder {
            $name = $remainder;

            $remainder = Str;
        }

        if $name {
            $name = decode trim-slashes $name;

            %args<name> = $name;
        }
        else {
            die "Must have a name specified";
        }


        # namespace
        if $remainder {
            %args<namespace> = $remainder.split("/").map({
                decode $_ if $_
            }).join("/");
        }

        # Do all additional custom chekcs and value customizations
        my $customization = PURL::Type(%args<type>);
        unless $customization ~~ Failure {
            $customization .= new;

            # First do all of the checks
            $customization.check-naming(|%args<name namespace>);
            $customization.check-version(%args<version>);
            with %args<qualifiers> -> %qualifiers {
                $customization.check-qualifier($_) for %qualifiers;
            }
            with %args<subpath> -> @parts {
                $customization.check-subpath($_) for @parts;
            }

            # Then do all the canonicalizations
            %args<name> := $_
              with $customization.canonicalize-name(%args<name>);
            %args<namespace> := $_
              with $customization.canonicalize-namespace(%args<namespace>);
            %args<version> := $_
              with $customization.canonicalize-version(%args<version>);
            with %args<qualifiers> -> %qualifiers {
                %args<qualifiers> := %qualifiers.map({
                    $customization.canonicalize-qualifier($_)
                }).Map
            }
            with %args<subpath> -> @parts {
                %args<subpath> := @parts.map({
                    $customization.canonicalize-subpath($_)
                }).List;
            }
        }

        %args
    }

    multi method new(PURL: Str:D $spec) {
        self.bless: |self!hashify($spec)
    }

    method from-identity(PURL: Str:D $id) {
        die "Impossible to create PURL from '$id' because it is not pinned."
          unless is-pinned($id);

        my %spec =
          scheme    => "pkg",
          type      => "raku",
          namespace => auth($id),
          name      => short-name($id),
          version   => ver($id) ~ ("/$_" with api($id))
        ;
        %spec{.key} = .value for %_;

        self.bless: |%spec
    }

    method qualifiers(PURL:D:) { %!qualifiers.Map }

    method subpath(PURL:D:) {
        @!subpath ?? @!subpath.join("/") !! Nil
    }

    multi method Str(PURL:D:) {
        $!scheme
          ~ ":" ~ self.type
          ~ ("/$_.split("/").map(&encode).join("/")" with self.namespace)
          ~ "/&encode(self.name)"
          ~ ("@" ~ encode($_) with self.version)
          ~ ("?%!qualifiers.sort(*.key).map({
                .key ~ '=' ~ encode .value
            }).join("&")" if %!qualifiers)
          ~ ("#@!subpath.map(&encode).join("/")"
              if @!subpath)
    }
    multi method gist(PURL:D:) { self.Str }

    method CALL-ME(Str:D $spec --> Bool:D) { (try self!hashify($spec)).Bool }
}

# vim: expandtab shiftwidth=4
