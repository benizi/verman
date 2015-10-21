package Verman::Node;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/nodejs/node');
  $self
}

sub available {
  version_sort grep /^v/, shift->SUPER::_tags
}

sub install {
  my ($self, $version) = @_;
  $self->_get_source;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;
  <<BUILD;
cd $root/git &&
mkdir -p $build $versions &&
printf 'Extracting...' &&
git archive $version | (cd $build ; tar x) &&
printf 'Done\\n' &&
cd $build &&
./configure --prefix=$versions/$version &&
make &&
make install
BUILD
}

1;
