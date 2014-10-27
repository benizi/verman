package Verman::Go;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://code.google.com/p/go');
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

  #if ($ENV{VERMAN_DEBUG}) { use Pry; pry; }

  $self->no_pathlike(GOPATH => $root, 1);
  for my $lib (grep -d, @libs) {
    $self->pre_pathlike(GOPATH => $lib);
  }

  $self->no_path($root);
  $self->pre_path(path $goroot, 'bin');
}

sub install {
  my ($self, $version) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $goroot = path $versions, $version;
  my $url = $self->var($self->_varname('upstream'));
  <<BUILD;
([[ -d $root/hg ]] || hg clone $url $root/hg) &&
cd $root/hg &&
hg archive --rev $version $build &&
cd $build/src &&
GOROOT_FINAL=$versions/$version sh ./all.bash &&
mkdir -p $versions &&
mv $build $versions/$version &&
mkdir -p $root/path/$version &&
GOPATH=$root/path/$version $versions/$version/bin/go get code.google.com/p/go.tools/cmd/...
BUILD
}

1;
