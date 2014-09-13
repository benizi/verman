package Verman::Node;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  my $node = $self->var(node_root => path($self->var('root'), 'node'), 1);
  $self->var(node_versions => path($node, 'versions'), 1);
  $self->var(node_git => path($node, 'git'), 1);
  $self
}

sub setup_build {
  my $self = shift;
  my $git = $self->var('node_git');
  mkpath $git unless -d $git;
  die "Couldn't create $git: $!" unless -d $git;
}

sub available {
  my $self = shift;
  $self->setup_build;
  push_dir $self->var('node_git');
  my @tags = run qw/git tag/;
  pop_dir;
  version_sort grep /^v/, @tags;
}

1;
