package Verman::Ruby;
use strict;
use warnings;
use base 'Verman::SelfContained';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self
}

sub available {
  version_sort run qw/ruby-build --definitions/
}

sub after_path {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $version = $self->var($self->_vervar);
  my $base = path $versions, $version;
  my $gems = path $base, 'lib', 'ruby', 'gems';
  my $gem_bin = path $gems, 'bin';
  $self->pre_path($gem_bin);
  $self->no_pathlike(GEM_PATH => $root);
  $self->pre_pathlike(GEM_PATH => $gems);
  $self->env_vars(GEM_HOME => $gems);
  # TODO: jRuby-specific vars
}

sub install {
  my ($self, $version) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $prefix = path $versions, $version;
  <<BUILD;
ruby-build $version $prefix &&
verman ruby use $version gem install bundler
BUILD
}

1;
