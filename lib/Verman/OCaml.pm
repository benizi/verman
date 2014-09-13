package Verman::OCaml;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  my $ocaml = $self->var(ocaml_root => path($self->var('root'), 'ocaml'), 1);
  $self->var(ocaml_versions => path($ocaml, 'versions'), 1);
  $self
}

sub use {
  my ($self, $version, @rest) = @_;
  my $root = $self->var('ocaml_root');
  my $versions = $self->var('ocaml_versions');
  my $home = path $versions, $version;
  return 'No such OCaml' unless -d $home;
  $self->env_vars(ocaml_version => $version);
  $self->no_path($root);
  $self->pre_path(path $home, 'bin');
  exec { $rest[0] } @rest if @rest;
  "using $version"
}

1;
