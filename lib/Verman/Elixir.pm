package Verman::Elixir;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/elixir-lang/elixir');
  $self
}

sub available {
  version_sort grep /^v/, shift->SUPER::_tags
}

sub install {
  my ($self, $version) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;
  my $github = $self->upstream . "/archive/$version.tar.gz";
  <<BUILD;
mkdir -p $build $versions &&
if test -d $root/git
then
  printf 'Extracting...' &&
  cd $root/git &&
  git archive $version | (cd $build ; tar x)
else
  printf 'Downloading...' &&
  curl -Ls $github | (cd $build ; tar zx --strip-components=1)
fi &&
printf 'Done\\n' &&
cd $build &&
make clean &&
make compile &&
make PREFIX=$prefix install
BUILD
}

1;
