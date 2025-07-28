use Identity::Utils:ver<0.0.24+>:auth<zef:lizmat> <
  api auth is-pinned short-name ver
>;
use JSON::Fast:ver<0.19+>:auth<cpan:TIMOTIMO>;
use URI::Encode:ver<1.0+>:auth<zef:raku-community-modules>;

use PURL::Type:ver<0.0.8>:auth<zef:lizmat>;

#- helper subroutines ----------------------------------------------------------

# Is a given string a valid identifier
my sub is-identifier($_) {
    .contains: /^ <[a..z A..Z]> <[a..z A..Z 0..9 . _ -]>+ $/
}

# Trim leading and trailing
my sub trim-slashes(Str:D $_) { .subst(/^ '/'+ /).subst(/ '/'+ $/) }

#- PURL ------------------------------------------------------------------------
class PURL:ver<0.0.8>:auth<zef:lizmat> {
    has Str $.scheme = 'pkg';
    has Str $.type is required;
    has Str $.name;
    has Str $.namespace;
    has Str $.version;
    has Str %.qualifiers;
    has Str @!qualifier-names is built;

    # Kept as an array as to be able to filter out components
    # when canonicalizing.
    has Str @.subpath;

    submethod TWEAK() {
        @!qualifier-names ||= %!qualifiers.keys.sort;
    }

    # Create an argument hash for the given Package URL
    method !hashify(Str:D $spec) {
        my %args;
        my Str $remainder;

        # subpath
        with $spec.rindex("#") -> $index {
            %args<subpath> = $spec.substr($index + 1).split("/").map({
                if $_ {
                    my $decoded = uri_decode($_);
                    $decoded unless $decoded eq '.' | '..';
                }
            }).List;

            $remainder = $spec.substr(0, $index);
        }
        else {
            $remainder = $spec;
        }

        # qualifiers
        with $remainder.rindex("?") -> $index {
            my %seen;

            %args<qualifier-names> := my @qualifier-names;  # UNCOVERABLE
            %args<qualifiers> = $remainder.substr($index + 1).split('&').map({
                my ($key, $value) = .split("=", 2);
                die "Invalid qualifier key: $key" unless is-identifier($key);

                $key .= lc;
                @qualifier-names.push($key);
                $key => uri_decode $value if $value;
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
            my $type = $remainder.substr(0,$index);
            die "Invalid type: $type" unless is-identifier($type);

            $type .= lc;  # canonicalize now for later checks
            %args<type> = $type;

            $remainder = $remainder.substr($index + 1);
        }
        else {
            die "Must have a type specified";
        }

        # name
        my $name;
        with $remainder.rindex("/") -> $index {
            $name = $remainder.substr($index + 1);

            $remainder = $remainder.substr(0, $index);
        }
        elsif $remainder {  # UNCOVERABLE
            $name = $remainder;  # UNCOVERABLE

            $remainder = Str;
        }

        if $name {

            # version
            with $name.rindex("@") -> $index {
                %args<version> = uri_decode $name.substr($index + 1);

                $name = $name.substr(0, $index);
            }

            $name = uri_decode trim-slashes $name;

            %args<name> = $name;
        }

        # namespace
        if $remainder {
            %args<namespace> = $remainder.split("/").map({
                uri_decode $_ if $_
            }).join("/");
        }

        check-and-canonicalize %args
    }

    # Do all additional custom checks and value customizations
    my sub check-and-canonicalize(%args) {
        my $customization = PURL::Type(%args<type>);
        unless $customization ~~ Failure {
            $customization .= new;

            # First do all of the checks
            $customization.check-identity(|%args<name namespace version>);
            with %args<qualifiers> -> %qualifiers {
                $customization.check-qualifier($_) for %qualifiers;
            }
            with %args<subpath> -> $parts {
                $customization.check-subpath($_) for $parts;
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
            with %args<subpath> -> $parts {
                %args<subpath> := $parts.map({
                    $customization.canonicalize-subpath($_)
                }).List;
            }
        }

        %args
    }

    multi method new(PURL:) {
        self.bless: |check-and-canonicalize %_
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
          version   => ver($id) ~ (":$_" with api($id))
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
          ~ ("/$_.split("/").map(&uri_encode).join("/")" with self.namespace)
          ~ ("/&uri_encode($_)"   with self.name)
          ~ ("@" ~ uri_encode($_) with self.version)
          ~ ("?" ~ (%!qualifiers{@!qualifier-names}:p).map({
                .key ~ '=' ~ uri_encode .value
            }).join("&") if %!qualifiers)
          ~ ("#@!subpath.map(&uri_encode).join("/")"
              if @!subpath)
    }
    multi method gist(PURL:D:) { self.Str }

    method CALL-ME(Str:D $spec --> Bool:D) { (try self!hashify($spec)).Bool }
}

# vim: expandtab shiftwidth=4
