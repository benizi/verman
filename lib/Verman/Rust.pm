package Verman::Rust;
use strict;
use warnings;
use base 'Verman::SelfContained';
use Verman::Util qw/path/;

sub after_path {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $lib = path $self->var($self->_versvar), $self->var($self->_vervar), 'lib';
  $self->no_pathlike(LD_LIBRARY_PATH => $root, 1);
  $self->pre_pathlike(LD_LIBRARY_PATH => $lib)
}

sub _triple {
  map +(split)[1], grep /^Target:/, readpipe 'clang --version'
}

sub install {
  my ($self, $version) = @_;
  my $base = join '-', rust => $version => $self->_triple;
  my $file = "$base.tar.gz";
  my $url = "https://static.rust-lang.org/dist/$file";
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;
  my $cache = path $root, 'downloads';
  <<BUILD;
mkdir -p $build $cache $versions &&
printf 'Downloading %s...\\n' "$url" &&
(test -f $cache/$file || curl -o $cache/$file \\
 $url) &&
printf 'Done\\n' &&
tar xzf $cache/$file -C $build &&
$build/$base/install.sh --prefix=$prefix
BUILD
}

1;
