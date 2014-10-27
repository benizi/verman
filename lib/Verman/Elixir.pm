package Verman::Elixir;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/elixir-lang/elixir.git');
  $self
}

# To install:
#   mkdir -p /opt/elixir
#   git clone https://github.com/elixir-lang/elixir.git /opt/elixir/git
#   cd /opt/elixir/git
#   version=v1.0.0
#   git checkout -f $version
#   make clean
#   make compile
#   make PREFIX=/opt/elixir/versions/$version install

1;
