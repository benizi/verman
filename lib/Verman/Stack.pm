package Verman::Stack;
use strict;
use warnings;
use base 'Verman::SelfContained';
use Verman::Util qw/path/;

sub install {
  my ($self, $version) = @_;
  (my $vnum = $version) =~ s/^v//;
  my $download = "https://github.com/commercialhaskell/stack/releases/download";
  my $file = "stack-$vnum-linux-x86_64.tar.gz";
  my $url = "$download/v$vnum/$file";
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $prefix = path $versions, $version;
  my $cache = path $root, 'downloads';
  <<BUILD;
mkdir -p $cache $prefix &&
printf 'Downloading %s...\\n' "$url" &&
(test -f $cache/$file || curl -L -o $cache/$file $url) &&
printf 'Done\\n' &&
tar --strip-components=1 -xzf $cache/$file -C $prefix &&
mkdir -p $prefix/bin &&
mv $prefix/stack $prefix/bin/
BUILD
}

sub available {
  qw{v0.1.8.0 v1.0.2}
}

1;
