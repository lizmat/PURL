use JSON::Fast:ver<0.19+>:auth<cpan:TIMOTIMO>;

class PURL:ver<0.0.1>:auth<zef:lizmat> {
    has Str $.scheme is required;
    has Str $.type   is required;
    has Str $.name   is required;
    has Str $.namespace;
    has Str $.version;
    has Str %.qualifiers;

    # Kept as an array as to be able to filter out components
    # when canonicalizing.
    has Str @.subpath;

    method !hashify(Str:D $spec) {
        my %args;

        my Str $remainder;
        with $spec.rindex("#") -> $index {
            %args<subpath> := $spec.substr($index + 1).split("/").map({
                decode($_) if $_;
            }).List;

            $remainder = $spec.substr(0, $index);
        }
        else {
            $remainder = $spec;
        }

        with $remainder.rindex("?") -> $index {
            my %seen;
            %args<qualifiers> := $remainder.substr($index + 1).split('&').map({
                my ($key, $value) = .split("=", 2);
                die "Invalid qualifier key: $key" unless is-identifier($key);

                if $value {
                    $value = decode $value;
                    $key.lc => $key eq "checksum"
                      ?? ($value = $value.split(",").List)
                      !! $value
                }
            }).Map;

            $remainder = $remainder.substr(0, $index);
        }

        my Str $scheme;
        with $remainder.index(":") -> $index {
            %args<scheme> := $remainder.substr(0,$index);

            die "Scheme must be 'pkg'" unless %args<scheme> eq 'pkg';
            $remainder = $remainder.substr($index + 1);
        }
        else {
            die "Must have a scheme specified";
        }

        $remainder = trim-slashes $remainder;

        with $remainder.index("/") -> $index {
            my $type := $remainder.substr(0,$index);
            die "Invalid type: $type" unless is-identifier($type);

            %args<type> := $type;

            $remainder = $remainder.substr($index + 1);
        }
        else {
            die "Must have a type specified";
        }

        with $remainder.rindex("@") -> $index {
            %args<version> := decode $remainder.substr($index + 1);

            $remainder = $remainder.substr(0, $index);
        }
        elsif %args<type> eq 'cran' | 'swift' {
            die "'%args<type>' requires a version specification";
        }

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

            %args<name> := $name;
        }
        else {
            die "Must have a name specified";
        }


        if $remainder {
            %args<namespace> = $remainder.split("/").map({
                decode $_ if $_
            }).join("/");
        }
        elsif %args<type> eq 'swift' {
            die "'%args<type> requires a namespace";
        }

        %args
    }

    multi method new(PURL: Str:D $spec) {
        self.bless: |self!hashify($spec)
    }

    method type(PURL:D:) { $!type.lc }

    method name(PURL:D:) {
        my constant %verbatim = <
          cpan cran hackage huggingface maven mlflow nuget swift
        >.Set;

        my $type := self.type;
        %verbatim{$type}
          ?? $!name
          !! $type eq 'pypi'
            ?? $!name.lc.trans("_" => "-")
            !! $!name.lc
    }

    method namespace(PURL:D:) {
        my constant %verbatim = <
          cpan huggingface maven swift
        >.Set;

        with $!namespace {
            %verbatim{self.type} ?? $_ !! .lc
        }
        else {
            Str
        }
    }

    method version(PURL:D:) {
        my constant %verbatim = <
          maven
        >.Set;

        with $!version {
            %verbatim{self.type} ?? $_ !! .lc
        }
        else {
            Str
        }
    }

    method qualifiers(PURL:D:) { %!qualifiers.Map }

    method subpath(PURL:D:) {
        @!subpath ?? @!subpath.join("/") !! Nil
    }

    multi method Str(PURL:D:) {
        $!scheme
          ~ ":" ~ self.type
          ~ ("/" ~ encode($_) with self.namespace)
          ~ "/" ~ self.name
          ~ ("@$_" with self.version)
          ~ ("?%!qualifiers.sort(*.key).map({ .key ~ '=' ~ encode .value }).join("&")"
              if %!qualifiers)
          ~ ("#" ~ @!subpath.grep({ !($_ eq '.' | '..') }).join("/")
              if @!subpath)
    }

    method CALL-ME(Str:D $spec --> Bool:D) { (try self!hashify).Bool }
}

my sub is-identifier($_) {
    .contains: /^ <[a..z A..Z]> <[a..z A..Z 0..9 . _ -]>+ $/
}

my sub trim-slashes(Str:D $_) { .subst(/^ '/'+ /).subst(/ '/'+ $/) }

my sub encode(Str:D $_) {
  .subst:
    / <-[a..z A..Z 0..9 _ ~ . -]> /,
    '%' ~ *.ord.fmt('%02x'),
    :global
}

my sub decode(Str:D $_) {
  .subst:
    / '%' <[0..9 a..f A..F]> ** 2 /,
    *.substr(1).parse-base(16).chr,
    :global
}

# vim: expandtab shiftwidth=4
