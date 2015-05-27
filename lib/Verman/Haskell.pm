package Verman::Haskell;
use strict;
use warnings;
use base 'Verman::SelfContained';
use Verman::Util;

sub install {
  my ($self, $version) = @_;
  my $file = "haskell-platform-${version}-unknown-linux-x86_64.tar.gz";
  my $url = "https://www.haskell.org/platform/download/$version/$file";
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $cache = path $root, 'cache';
  my $prefix = path $versions, $version;
  my $stubs = path $root, 'stubs'; # to trick installer into allowing non-root

  <<INSTALL;
tempdir=\$(mktemp -d) &&
trap 'test -n "\$tempdir\" && rm -r \${tempdir:?}' INT QUIT EXIT HUP &&
mkdir -p $cache $versions $stubs \$tempdir/bin \$tempdir/share/man/man1 &&
printf '%s\\n' '#!/bin/sh' 'echo 0' > $stubs/id &&
chmod +x $stubs/id &&
(test -f $cache/$file || curl -o $cache/$file $url) &&
actual=\$(tar -tf $cache/$file | sed 1q) &&
actual=/\${actual%/} &&
haskell=\$(dirname \$actual) &&
mkdir -p \$haskell &&
ln -nsf \$actual $prefix &&
cd / &&
tar -xvf $cache/$file &&
PATH=$stubs:\$PATH $prefix/bin/activate-hs --prefix \$tempdir &&
echo ...but not really
INSTALL
}

sub available {
  '2014.2.0.0'
}

1;
