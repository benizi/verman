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

sub after_path {
  my ($self) = @_;
  my $versions = $self->var($self->_versvar);
  my $v = $self->var($self->_vervar);
  $self->no_pathlike(NODE_PATH => $versions, 1);
  $self->pre_pathlike(NODE_PATH => path $versions, $v, 'lib', 'node_modules');
}

1;
