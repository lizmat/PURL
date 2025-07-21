#- introspection ---------------------------------------------------------------
# Set up description lookup
my %description := BEGIN {
    my @lines = %?RESOURCES<known-types>.open.lines(:close);
    my %hash;

    while @lines {
        my $type        = @lines.shift;
        my $description = @lines.shift;

        while @lines && @lines.shift -> $extra {
            $description ~= "\n$extra";
        }
        %hash{$type} := $description;
    }

    %hash.Map
}

# Set up examples lookup
my %examples := BEGIN {
    my @lines = %?RESOURCES<examples>.open.lines(:close);
    my %hash;

    while @lines {
        my $type     = @lines.shift;
        my @examples = @lines.shift;

        while @lines && @lines.shift -> $extra {
            @examples.push($extra);
        }
        %hash{$type} := @@examples.List;
    }

    %hash.Map
}

#- PURL::Type ------------------------------------------------------------------
class PURL::Type:ver<0.0.5>:auth<zef:lizmat> {
    method default-repository() { "" }

    method check-naming($, $ --> Nil) { }
    method check-version(  $ --> Nil) { }
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
        <arch distro repository_url>
    }
}

class PURL::apk is PURL::Type {
    method qualifier-keys() {
        <arch distro repository_url>
    }
}

#- B ---------------------------------------------------------------------------
class PURL::bitbucket is PURL::Type {
    method default-repository() {
        "https://bitbucket.org"
    }
}

class PURL::bitnami is PURL::Type {
    method default-repository() {
        "https://downloads.bitnami.com/files/stacksmith"
    }
}

#- C ---------------------------------------------------------------------------
class PURL::cargo is PURL::Type {
    method default-repository() {
        "https://crates.io"
    }

    method canonicalize-name($_) { $_ }
}

class PURL::cocoapods is PURL::Type {
    method default-repository() {
        "https://cdn.cocoapods.org/"
    }
    method check-naming($name, $ --> Nil) {
        die "Name '$name' not allowed to contain whitespace"
          if $name.contains(/ \s /);
        die "Name '$name' not allowed to contain '+'"
          if $name.contains('+');
        die "Name '$name' not allowed to contain '.'"
          if $name.contains('.');
    }
}

class PURL::composer is PURL::Type {
    method default-repository() {
        "https://packagist.org"
    }
}

class PURL::conan is PURL::Type {
    method qualifier-keys() {
        <build_type channel os prev repository_url rrev shared user>
    }
}

class PURL::conda is PURL::Type {
    method default-repository() {
        "https://repo.anaconda.com"
    }
    method qualifier-keys() {
        <build channel subdir type>
    }
}

class PURL::cpan is PURL::Type {    # XXX
    method default-repository() {
        "https://www.cpan.org/"
    }
    method qualifier-keys() {
        <download_url ext repository_url vcs_url>
    }
    method check-naming($name, $namespace --> Nil) {
        if $namespace {
            die "Namespace must consist of uppercase ascii only: '$namespace'"
              if $namespace.contains(/ <:lower> /);
            die "Name may not contain '::': '$name'"
              if $name.contains('::');
        }
        elsif $name {
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
        "https://cran.r-project.org"
    }
    method qualifier-keys() {
        <build channel subdir type>
    }
    method check-naming($, $namespace --> Nil) {
        die "Cannot have a namespace specified" if $namespace;
    }
    method check-version($version) {
        die "Must have a version specified" unless $version;
    }
    method canonicalize-name($_) { $_ }
}

#- D ---------------------------------------------------------------------------
class PURL::deb is PURL::Type {
    method qualifier-keys() {
        <arch distro repository_url>
    }
    method check-naming($, $namespace --> Nil) {
        die "Must have a namespace specified" unless $namespace;
    }
}

class PURL::docker is PURL::Type {
    method default-repository() {
        "https://hub.docker.com"
    }
}

#- G ---------------------------------------------------------------------------
class PURL::gem is PURL::Type {
    method default-repository() {
        "https://rubygems.org"
    }
}

class PURL::generic is PURL::Type {
    method qualifier-keys() {
        <download_url checksum>
    }
}

class PURL::github is PURL::Type {
    method default-repository() {
        "https://github.com"
    }
}

class PURL::golang is PURL::Type {
}

#- H ---------------------------------------------------------------------------
class PURL::hackage is PURL::Type {
    method default-repository() {
        "https://hackage.haskell.org/"
    }
    method canonicalize-name($_) { $_ }
}

class PURL::hex is PURL::Type {
    method default-repository() {
        "https://repo.hex.pm"
    }
}

class PURL::huggingface is PURL::Type {
    method default-repository() {
        "https://huggingface.co"
    }
    method canonicalize-namespace($_) { $_ }
    method canonicalize-name(     $_) { $_ }
    method canonicalize-version(  $_) { .lc }
}

#- L ---------------------------------------------------------------------------
class PURL::luarocks is PURL::Type {
    method qualifier-keys() {
        <repository_url>
    }
    method canonicalize-namespace($_) { $_ }
    method canonicalize-name(     $_) { $_ }
    method canonicalize-version(  $_) { $_ }
}

#- M ---------------------------------------------------------------------------
class PURL::maven is PURL::Type {
    method default-repository() {
        "https://repo.maven.apache.org/maven2"
    }
    method qualifier-keys() {
        <classifier repository_url type>
    }
    method canonicalize-name($_) { $_ }
    method canonicalize-namespace($_) { $_ }
}

class PURL::mlflow is PURL::Type {
    has $!lower-case;

    method default-repository() {
        "https://repo.maven.apache.org/maven2"
    }
    method qualifier-keys() {
        <model_uuid run_id>
    }
    method check-naming($, $namespace --> Nil) {
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
        "https://registry.npmjs.org"
    }
}

class PURL::nuget is PURL::Type {
    method default-repository() {
        "https://www.nuget.org"
    }
    method canonicalize-name($_) { $_ }
}

#- O ---------------------------------------------------------------------------
class PURL::oci is PURL::Type {
    method default-repository() {
        "https://www.nuget.org"
    }
    method qualifier-keys() {
        <arch repository_url tag>
    }
}

#- P ---------------------------------------------------------------------------
class PURL::pub is PURL::Type {
    method default-repository() {
        "https://pub.dartlang.org"
    }
    method check-naming($name, $namespace --> Nil) {
        die "Name may only consists of a-z, 0-9 and _: '$name'"
          if $name && $name.contains(/ <-[a..z 0..9 _]> /);
        die "Namespace may only consists of a-z, 0-9 and _: '$namespace'"
          if $namespace && $namespace.contains(/ <-[a..z 0..9 _]> /);
    }
}

class PURL::pypi is PURL::Type {
    method default-repository() {
        "https://pypi.org"
    }
    method qualifier-keys() {
        <file_name>
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
        <download_url repository_url>
    }
    method canonicalize-name(     $_) { $_ }
    method canonicalize-namespace($_) { $_ }
}

class PURL::rpm is PURL::Type {
    method qualifier-keys() {
        <arch distro epoch repository_url>
    }
    method canonicalize-name($_) { $_ }
}

#- S ---------------------------------------------------------------------------
class PURL::swid is PURL::Type {
    method qualifier-keys() {
        <download_url patch
         tag_creator_name tag_creator_regid tag_id tag_version>
    }
}

class PURL::swift is PURL::Type {
    method check-naming($, $namespace) {
        die "Must have a namespace specified" unless $namespace;
    }
    method check-version($version) {
        die "Must have a version specified" unless $version;
    }
    method canonicalize-name($_) { $_ }
    method canonicalize-namespace($_) { $_ }
}

# vim: expandtab shiftwidth=4
