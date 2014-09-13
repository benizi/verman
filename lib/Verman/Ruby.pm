package Verman::Ruby;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;

sub use {
  my ($self, $version, @rest) = @_;
  my $root = $self->ruby_root;
  my $base = path $root, $version;
  my $gems = path $base, 'lib', 'ruby', 'gems';
  $self->env_vars(
    GEM_PATH => ,
    GEM_HOME => ,
    ruby_version => $version,
  );
  $self->no_path($root);
  $self->pre_path(path $base, 'bin');
  $self->pre_path(path $gems, 'bin');
  exec { $rest[0] } @rest if @rest;
  "using $version"
}

1;
