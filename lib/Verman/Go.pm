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

sub install {
  my ($self, $version) = @_;
  $self->_get_source;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $goroot = path $versions, $version;
  <<BUILD;
cd $root/git &&
mkdir -p $build $versions &&
printf 'Extracting...' &&
git archive $version | (cd $build ; tar x) &&
printf 'Done\\n' &&
cd $build/src &&
GOROOT_FINAL=$versions/$version sh ./all.bash &&
mv $build $versions &&
GOPATH=$root/path/$version $goroot/bin/go get golang.org/x/tools/cmd/...
BUILD
}

1;
