package Verman::Rust;
use strict;
use warnings;
use base 'Verman::SelfContained';
use Verman::Util qw/path mkpath version_sort/;

sub after_path {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $version = path $self->var($self->_versvar), $self->var($self->_vervar);
  my $lib = path $version, 'lib';
  my $cargo = path $version, 'cargo';
  $self->no_pathlike(LD_LIBRARY_PATH => $root, 1);
  $self->pre_pathlike(LD_LIBRARY_PATH => $lib);
  $self->pre_path(path $cargo, 'bin');
  $self->env_vars(CARGO_HOME => $cargo);
}

sub _triple {
  local $_ = (map +(split)[1], grep /^Target:/, readpipe 'clang --version')[0];
  s/(?<=-)pc(?=-linux)/unknown/;
  $_
}

sub _dist {
  my ($self, @rest) = @_;
  join '/', 'https://static.rust-lang.org/dist', @rest
}

sub available {
  my ($self) = @_;
  my $root = $self->var($self->_rootvar);
  my $url = $self->_dist('index.html');
  my $cache = path $root, 'cache';
  my $html = path $cache, 'index.html';
  eval { mkpath $cache };
  -e $cache or die "Couldn't cache Rust version list (cache=$cache): $@";
  unless (-e $html and 1 > -M $html) {
    system { 'curl' } qw/curl -s -o/, $html, $url and die "$@";
  }
  open my $f, '<', $html or die "$@";
  my @files;
  local $_;
  while (<$f>) {
    chomp;
    next unless m{<td class="filename"><a[^>]*>([^<]+)</a></td>};
    push @files, $1;
  }
  my $triple = $self->_triple;
  my $triple_tar = qr/\Q$triple.tar.gz\E/;
  version_sort map +(split '-')[1], grep /^rust-\d.*-$triple_tar$/, @files
}

sub install {
  my ($self, $version) = @_;
  my $base = join '-', rust => $version => $self->_triple;
  my $file = "$base.tar.gz";
  my $url = $self->_dist($file);
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;
  my $cache = path $root, 'downloads';
  <<BUILD;
set -e
mkdir -p $build $cache $versions
printf 'Downloading %s...\\n' "$url"
test -f $cache/$file || curl -o $cache/$file \\
 $url
printf 'Done\\n'
tar xzf $cache/$file -C $build
$build/$base/install.sh --prefix=$prefix
BUILD
}

1;
