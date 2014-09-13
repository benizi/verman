package Verman::Ghc;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  my $ghc = $self->var(ghc_root => path($self->var('root'), 'ghc'), 1);
  $self->var(ghc_versions => path($ghc, 'versions'), 1);
  $self
}

sub use {
  my ($self, $version, @rest) = @_;
  my $root = $self->var('ghc_root');
  my $versions = $self->var('ghc_versions');
  my $home = path $versions, $version;
  return 'No such GHC' unless -d $home;
  $self->env_vars(ghc_version => $version);
  $self->no_path($root);
  $self->pre_path(path $home, 'bin');
  exec { $rest[0] } @rest if @rest;
  "using $version"
}

1;
