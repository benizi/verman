package Verman::Node;
use strict;
use warnings;
use base 'Verman::Nix', 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/nodejs/node');
  $self
}

sub _non_nix_available {
  version_sort grep /^v/, shift->SUPER::_tags
}

sub _nix_stub_dirs {
  my $self = shift;
  my ($v, $prefix) = @_;
  path $prefix, 'bin'
}

sub _nix_symlinks {
  my $self = shift;
  my ($v, $prefix, $nix_root) = @_;
  my $bin = path $prefix, 'bin';
  map [$bin, "$nix_root/bin/$_"], qw/node npm npx/
}

sub _make_install {
  my ($self, $prefix) = @_;
  <<BUILD;
./configure --prefix=$prefix
make
make install
BUILD
}

sub after_path {
  my ($self) = @_;
  my $versions = $self->var($self->_versvar);
  my $v = $self->var($self->_vervar);
  my $prefix = path $versions, $v;
  $self->no_pathlike(NODE_PATH => $versions, 1);
  $self->pre_pathlike(NODE_PATH => path $prefix, 'lib', 'node_modules');
  $self->env_vars(NPM_CONFIG_PREFIX => $prefix)
}

sub _nix_version_prefix { 'v' }
sub _nixpkg { 'nodejs' }

1;
