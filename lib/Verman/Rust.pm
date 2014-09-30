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

1;
