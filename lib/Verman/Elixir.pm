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

sub _make_install {
  my ($self, $prefix) = @_;
  <<BUILD;
make clean
make compile
make PREFIX=$prefix install
BUILD
}

sub after_path {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $version = $self->var($self->_vervar);
  $self->env_vars(MIX_HOME => path $root, 'versions', $version, 'mix')
}

1;
