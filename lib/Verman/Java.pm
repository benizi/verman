package Verman::Java;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;

sub use {
  my ($self, $version, @rest) = @_;
  my $root = $self->var('java_root');
  my $home = path $root, $version;
  return 'No such Java' unless -d $home;
  $self->env_vars(
    JAVA_HOME => $home,
    java_version => $version,
  );
  $self->no_path($root);
  $self->pre_path(path $home, 'bin');
  exec { $rest[0] } @rest if @rest;
  "using $version"
}

1;
