package Verman::Go;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://go.googlesource.com/go');
  $self
}

sub available {
  version_sort grep /^go/, shift->SUPER::_tags
}

sub after_path {
  my ($self) = @_;
  my $root = $self->var($self->_rootvar);
  my $v = $self->var($self->_vervar);
  my $versions = $self->var($self->_versvar);
  my $goroot = path $versions, $v;
  my @libs;

  # vv TODO: GVM transition
  my $gvm_pkgset = path $root, 'pkgsets', $v, 'global';
  unshift @libs, $gvm_pkgset;
  # ^^ TODO: GVM transition

  unshift @libs, "$ENV{HOME}/gopath/$v";

  unshift @libs, path $root, 'path', $v;

  $self->no_path($root);
  $self->pre_path(path $goroot, 'bin');

  $self->no_pathlike(GOPATH => $root, 1);
  for my $lib (grep -d, @libs) {
    $self->pre_pathlike(GOPATH => $lib);
    $self->pre_path(path $lib, 'bin');
  }
}

sub _make_install {
  my ($self, $goroot, $version) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $gopath = path $root, 'path', $version;
  my $bootstrap = path $versions, 'go1.4.1';
  <<BUILD;
cd src
GOROOT_BOOTSTRAP=$bootstrap GOROOT_FINAL=$goroot sh ./all.bash
cd $root
mv $build $versions
GOPATH=$gopath $goroot/bin/go get golang.org/x/tools/cmd/...
BUILD
}

1;
