#- introspection ---------------------------------------------------------------
# Set up description lookup
my %description := BEGIN {
    my @lines = %?RESOURCES<known-types>.open.lines(:close);
    my %hash;

    while @lines {  # UNCOVERABLE
        my $type        = @lines.shift;
        my $description = @lines.shift;

        while @lines && @lines.shift -> $extra {  # UNCOVERABLE
            $description ~= "\n$extra";  # UNCOVERABLE
        }
        %hash{$type} := $description;  # UNCOVERABLE
    }

    %hash.Map  # UNCOVERABLE
}

# Set up examples lookup
my %examples := BEGIN {
    my @lines = %?RESOURCES<examples>.open.lines(:close);
    my %hash;

    while @lines {  # UNCOVERABLE
        my $type     = @lines.shift;
        my @examples = @lines.shift;

        while @lines && @lines.shift -> $extra {  # UNCOVERABLE
            @examples.push($extra);  # UNCOVERABLE
        }
        %hash{$type} := @@examples.List;  # UNCOVERABLE
    }

    %hash.Map  # UNCOVERABLE
}

#- PURL::Type ------------------------------------------------------------------
class PURL::Type:ver<0.0.15>:auth<zef:lizmat> {
    method default-repository() { "" }

    method check-identity($name, $, $ --> Nil) {
        die "Must have a name specified" unless $name;
    }
    method check-qualifier($ --> Nil) { }
    method check-subpath(  $ --> Nil) { }

    method canonicalize-namespace($_) { $_ ?? .lc !! $_ }
    method canonicalize-name(     $_) { $_ ?? .lc !! $_ }

    method canonicalize-version(  $_) { $_ }
    method canonicalize-qualifier($_) { $_ }
    method canonicalize-subpath(  $_) { $_ }

    method qualifier-keys() { () }

    proto method description(|) {*}
    multi method description() {
        self.description(self.^name.substr(6))
    }
    multi method description(Str:D $type) {
        %description{$type} // "No description for: $type"
    }

    proto method examples(|) {*}
    multi method examples() {
        self.examples(self.^name.substr(6))
    }
    multi method examples(Str:D $type) {
        %examples{$type} // ()
    }

    method supported-names() {
        %description.keys.sort.List
    }
    method supported-types() {
        self.supported-names.map({ ::("PURL::$_") }).List
    }

    method CALL-ME(Str:D $_) { ::("PURL::$_") }
}

#- A ---------------------------------------------------------------------------
class PURL::alpm is PURL::Type {
    method qualifier-keys() {
        <arch distro repository_url>  # UNCOVERABLE
    }
}

class PURL::apk is PURL::Type {
    method qualifier-keys() {
        <arch distro repository_url>  # UNCOVERABLE
    }
}

#- B ---------------------------------------------------------------------------
class PURL::bitbucket is PURL::Type {
    method default-repository() {
        "https://bitbucket.org"  # UNCOVERABLE
    }
}

class PURL::bitnami is PURL::Type {
    method default-repository() {
        "https://downloads.bitnami.com/files/stacksmith"  # UNCOVERABLE
    }
}

#- C ---------------------------------------------------------------------------
class PURL::cargo is PURL::Type {
    method default-repository() {
        "https://crates.io"  # UNCOVERABLE
    }

    method canonicalize-name($_) { $_ }
}

class PURL::cocoapods is PURL::Type {
    method default-repository() {
        "https://cdn.cocoapods.org/"  # UNCOVERABLE
    }
    method check-identity($name, $, $ --> Nil) {
        die "Must have a name specified" unless $name;
        die "Name '$name' not allowed to contain whitespace"
          if $name.contains(/ \s /);
        die "Name '$name' not allowed to contain '+'"
          if $name.contains('+');
        die "Name '$name' not allowed to contain '.'"
          if $name.contains('.');
    }

    method canonicalize-name($_) { $_ }
}

class PURL::composer is PURL::Type {
    method default-repository() {
        "https://packagist.org"  # UNCOVERABLE
    }
}

class PURL::conan is PURL::Type {
    method qualifier-keys() {
        <build_type channel os prev repository_url rrev shared user>  # UNCOVERABLE
    }
}

class PURL::conda is PURL::Type {
    method default-repository() {
        "https://repo.anaconda.com"  # UNCOVERABLE
    }
    method qualifier-keys() {
        <build channel subdir type>  # UNCOVERABLE
    }
}

class PURL::cpan is PURL::Type {    # XXX
    method default-repository() {
        "https://www.cpan.org/"  # UNCOVERABLE
    }
    method qualifier-keys() {
        <download_url ext repository_url vcs_url>  # UNCOVERABLE
    }
    method check-identity($name, $namespace, $version --> Nil) {
        if $namespace {
            die "Refers to a Raku package on CPAN, please use 'pkg:raku/$namespace.substr(0,*-6)/$name@$version' instead"
              if $namespace.ends-with("/Perl6");
            die "Namespace must consist of uppercase ascii only: '$namespace'"
              if $namespace.contains(/ <:lower> /);
            die "Name may not contain '::': '$name'"
              if $name.contains('::');
        }
        elsif $name {  # UNCOVERABLE
            die "Name may not contain hyphens: '$name'"
              if $name.contains("-");
        }
        else {
            die "Must have at least a name specified";
        }
    }
    method canonicalize-name($_) { $_ }
    method canonicalize-namespace($_) { $_ }
}

class PURL::cran is PURL::Type {
    method default-repository() {
        "https://cran.r-project.org"  # UNCOVERABLE
    }
    method qualifier-keys() {
        <build channel subdir type>  # UNCOVERABLE
    }
    method check-identity($name, $namespace, $version --> Nil) {
        die "Must have a name specified"    unless $name;
        die "Cannot have a namespace specified" if $namespace;
        die "Must have a version specified" unless $version;
    }
    method canonicalize-name($_) { $_ }
}

#- D ---------------------------------------------------------------------------
class PURL::deb is PURL::Type {
    method qualifier-keys() {
        <arch distro repository_url>  # UNCOVERABLE
    }
    method check-identity($name, $namespace, $ --> Nil) {
        die "Must have a name specified"      unless $name;
        die "Must have a namespace specified" unless $namespace;
    }
}

class PURL::docker is PURL::Type {
    method default-repository() {
        "https://hub.docker.com"  # UNCOVERABLE
    }
}

#- G ---------------------------------------------------------------------------
class PURL::gem is PURL::Type {
    method default-repository() {
        "https://rubygems.org"  # UNCOVERABLE
    }
}

class PURL::generic is PURL::Type {
    method qualifier-keys() {
        <download_url checksum>  # UNCOVERABLE
    }
}

class PURL::github is PURL::Type {
    method default-repository() {
        "https://github.com"  # UNCOVERABLE
    }
}

class PURL::golang is PURL::Type {
}

#- H ---------------------------------------------------------------------------
class PURL::hackage is PURL::Type {
    method default-repository() {
        "https://hackage.haskell.org/"  # UNCOVERABLE
    }
    method canonicalize-name($_) { $_ }
}

class PURL::hex is PURL::Type {
    method default-repository() {
        "https://repo.hex.pm"  # UNCOVERABLE
    }
}

class PURL::huggingface is PURL::Type {
    method default-repository() {
        "https://huggingface.co"  # UNCOVERABLE
    }
    method canonicalize-namespace($_) { $_ }
    method canonicalize-name(     $_) { $_ }
    method canonicalize-version(  $_) { .lc }
}

#- L ---------------------------------------------------------------------------
class PURL::luarocks is PURL::Type {
    method qualifier-keys() {
        <repository_url>  # UNCOVERABLE
    }
    method canonicalize-namespace($_) { $_ }
    method canonicalize-name(     $_) { $_ }
    method canonicalize-version(  $_) { $_ }
}

#- M ---------------------------------------------------------------------------
class PURL::maven is PURL::Type {
    method default-repository() {
        "https://repo.maven.apache.org/maven2"  # UNCOVERABLE
    }
    method qualifier-keys() {
        <classifier repository_url type>  # UNCOVERABLE
    }
    method canonicalize-name($_) { $_ }
    method canonicalize-namespace($_) { $_ }
}

class PURL::mlflow is PURL::Type {
    has $!lower-case;

    method default-repository() {
        "https://repo.maven.apache.org/maven2"  # UNCOVERABLE
    }
    method qualifier-keys() {
        <model_uuid run_id>  # UNCOVERABLE
    }
    method check-identity($name, $namespace, $ --> Nil) {
        die "Must have a name specified"    unless $name;
        die "Cannot have a namespace specified" if $namespace;
    }
    method check-qualifier($_ --> Nil) {
        $!lower-case := True
          if .key eq 'repository_url' && .value.contains("databricks");
    }
    method canonicalize-name($_) {
        $!lower-case ?? .lc !! $_
    }
}

#- N ---------------------------------------------------------------------------
class PURL::npm is PURL::Type {
    method default-repository() {
        "https://registry.npmjs.org"  # UNCOVERABLE
    }
    method check-identity($, $, $ --> Nil) { }
}

class PURL::nuget is PURL::Type {
    method default-repository() {
        "https://www.nuget.org"  # UNCOVERABLE
    }
    method canonicalize-name($_) { $_ }
}

#- O ---------------------------------------------------------------------------
class PURL::oci is PURL::Type {
    method default-repository() {
        "https://www.nuget.org"  # UNCOVERABLE
    }
    method qualifier-keys() {
        <arch repository_url tag>  # UNCOVERABLE
    }
}

#- P ---------------------------------------------------------------------------
class PURL::pub is PURL::Type {
    method default-repository() {
        "https://pub.dartlang.org"  # UNCOVERABLE
    }
    method check-identity($name, $namespace, $ --> Nil) {
        die "Must have a name specified" unless $name;
        die "Name may only consists of a-z, 0-9 and _: '$name'"
          if $name && $name.contains(/ <-[a..z 0..9 _]> /);
        die "Namespace may only consists of a-z, 0-9 and _: '$namespace'"
          if $namespace && $namespace.contains(/ <-[a..z 0..9 _]> /);
    }
}

class PURL::pypi is PURL::Type {
    method default-repository() {
        "https://pypi.org"  # UNCOVERABLE
    }
    method qualifier-keys() {
        <file_name>  # UNCOVERABLE
    }
    method canonicalize-name($_) {
        .lc.subst("_", "-", :global)
    }
}

#- Q ---------------------------------------------------------------------------
class PURL::qpkg is PURL::Type {
}

#- R ---------------------------------------------------------------------------
class PURL::raku is PURL::Type {
    method qualifier-keys() {
        <download_url>  # UNCOVERABLE
    }

    method check-identity($name, $namespace, $version --> Nil) {
        die "Must have a name specified" unless $name;
        die "Namespace must start with 'zef:' or 'cpan:'"
          if !$namespace
          || !$namespace.starts-with("zef:" | "cpan:");
    }

    method canonicalize-name($_) { $_ }

    method canonicalize-namespace($_) {
        .starts-with("cpan:")
          ?? "cpan:" ~ .substr(5).uc
          !! $_
    }
}

class PURL::rpm is PURL::Type {
    method qualifier-keys() {
        <arch distro epoch repository_url>  # UNCOVERABLE
    }
    method canonicalize-name($_) { $_ }
}

#- S ---------------------------------------------------------------------------
class PURL::swid is PURL::Type {
    method qualifier-keys() {
        <download_url patch tag_creator_name tag_creator_regid tag_id tag_version> # UNCOVERABLE
    }
    method canonicalize-name($_) { $_ }
    method canonicalize-namespace($_) { $_ }
}

class PURL::swift is PURL::Type {
    method check-identity($name, $namespace, $version) {
        die "Must have a name specified"      unless $name;
        die "Must have a namespace specified" unless $namespace;
        die "Must have a version specified"   unless $version;
    }
    method canonicalize-name($_) { $_ }
    method canonicalize-namespace($_) { $_ }
}

# vim: expandtab shiftwidth=4
