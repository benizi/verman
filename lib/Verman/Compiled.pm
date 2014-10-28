package Verman::Compiled;
use strict;
use warnings;
use vars '$upstream';
use Verman::Util;
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

sub _get_source {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $git = path $root, 'git';
  return if -d $git;
  my $url = $self->var($self->_varname('upstream'));
  mkpath $root || die "Couldn't mkdir -p $root: $!";
  system { 'git' } git => clone => $url => $git
}

1;
