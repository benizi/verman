package Verman::SelfContained;
use strict;
use warnings;
use base 'Verman';
use Verman::Util;
our $_abstract;

# Clearly, I've forgotten how to write Perldoc...
#
=begin

=item Verman::SelfContained

=item SUMMARY

Base class for langs that only need to be added to $PATH

=cut

sub _rootvar { shift->_varname('root') }
sub _versvar { shift->_varname('versions') }
sub _vervar { shift->_varname('version') }

sub _varname {
  my $self = shift;
  join '_', $self->_lc_name, @_
}

sub _lc_name { lc shift->_name }

sub _name {
  my $self = shift;
  (split '::', ref $self)[-1]
}

sub new {
  my $self = shift->SUPER::new(@_);
  my $name = $self->_lc_name;
  my $root = $self->var($self->_rootvar => path($self->var('root'), $name), 1);
  $self->var($self->_versvar => path($root, 'versions'), 1);
  $self
}

sub use {
  my ($self, $version, @rest) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $home = path $versions, $version;
  return 'No such '.$self->_name unless -d $home;
  $self->env_vars($self->_varname('home') => $home);
  $self->var($self->_vervar => $version);
  $self->env_vars($self->_vervar => $version);
  $self->no_path($root);
  $self->pre_path(path $home, 'bin');
  $self->after_path if $self->can('after_path');
  exec { $rest[0] } @rest if @rest;
  "using $version"
}

sub installed {
  my ($self) = @_;
  ls $self->var($self->_versvar)
}

1;
