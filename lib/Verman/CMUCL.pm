package Verman::CMUCL;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub available {
  grep !/18f/, grep /\d\d\D/, map sprintf("%3x", $_), 0x18a..0x20f
}

sub install {
  my ($self, $version) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $prefix = path $versions, $version;
  my $cache = path $root, 'downloads';
  my $base = "cmucl-$version-x86-linux.tar.bz2";
  my $extra = "cmucl-$version-x86-linux.extra.tar.bz2";
  my $url = "https://common-lisp.net/project/cmucl/downloads/release/$version";
  <<BUILD;
mkdir -p $cache $versions $prefix &&
for file in $base $extra ; do
printf 'Downloading %s...\\n' "$url/\$file" &&
(test -f $cache/\$file || curl -o $cache/\$file $url/\$file) &&
printf 'Done\\n'
done &&
cd $prefix &&
printf 'Extracting...' &&
tar xjf $cache/$base &&
tar xjf $cache/$extra
BUILD
}

1;
