package Verman::Haskell;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  my $haskell = $self->var(haskell_root => path($self->var('root'), 'haskell'), 1);
  $self->var(haskell_versions => path($haskell, 'versions'), 1);
  $self
}

sub use {
  my ($self, $version, @rest) = @_;
  my $root = $self->var('haskell_root');
  my $versions = $self->var('haskell_versions');
  my $home = path $versions, $version;
  return 'No such Haskell' unless -d $home;
  $self->env_vars(haskell_version => $version);
  $self->no_path($root);
  $self->pre_path(path $home, 'bin');
  exec { $rest[0] } @rest if @rest;
  "using $version"
}

1;
