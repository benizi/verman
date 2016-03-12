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

sub _make_install {
  my ($self, $prefix) = @_;
  <<BUILD;
./configure --prefix=$prefix
make
make install
BUILD
}

1;
