package Verman::Elixir;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/elixir-lang/elixir.git');
  $self
}

sub available {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  $self->_get_source;
  push_dir path $root, 'git';
  my @tags = run qw/git tag/;
  pop_dir;
  version_sort grep /^v/, @tags;
}

sub install {
  my ($self, $version) = @_;
  $self->_get_source;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;
  <<BUILD;
cd $root/git &&
mkdir -p $build $versions &&
printf 'Extracting...' &&
git archive $version | (cd $build ; tar x) &&
printf 'Done\\n' &&
cd $build &&
make clean &&
make compile &&
make PREFIX=$prefix install
BUILD
}

1;
