package Verman::FSharp;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/fsharp/fsharp');
  $self
}

sub available {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  $self->_get_source;
  push_dir path $root, 'git';
  my @tags = run qw/git tag/;
  pop_dir;
  version_sort @tags;
}

sub _make_install {
  my ($self, $prefix) = @_;
  <<BUILD;
./autogen.sh --prefix="$prefix" &&
make &&
make install
BUILD
}

1;
