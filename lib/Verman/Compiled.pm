package Verman::Compiled;
use strict;
use warnings;
use vars '$upstream';
our $_abstract;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('vcs'), 'git');
  $self
}

sub upstream {
  my $self = shift;
  $self->var($self->_varname('upstream'))
}

sub update {
  my $self = shift;
  #my $dest
  $self->upstream
}

1;
