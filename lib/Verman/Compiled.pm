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
  my $root = $self->var($self->_rootvar);
  run qw/git --git-dir/, path($root, 'git', '.git'), 'fetch'
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

sub _tags {
  my $self = shift;
  $self->_get_source;
  my $root = $self->var($self->_rootvar);
  push_dir path $root, 'git';
  my @tags = run qw/git tag/;
  pop_dir;
  @tags
}

1;
