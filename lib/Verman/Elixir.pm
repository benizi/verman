package Verman::Elixir;
use strict;
use warnings;
use base qw/Verman::Nix Verman::SelfContained Verman::Compiled/;
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/elixir-lang/elixir');
  $self
}

sub _non_nix_available {
  version_sort grep /^v/, shift->SUPER::_tags
}

sub _nix_stub_dirs {
  my ($self, $v) = @_;
  my ($root, $versions) = map $self->var($self->$_), qw/_rootvar _versvar/;
  map path(@$_, $v), [$versions], [$root, 'mix'];
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

sub _nix_version_prefix { 'v' }

1;
