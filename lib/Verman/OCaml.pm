package Verman::OCaml;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/ocaml/ocaml');
  $self
}

sub available {
  version_sort shift->SUPER::_tags
}

sub install {
  my ($self, $version) = @_;
  $self->_get_source;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;

  my $cache = path $root, 'cache';
  my $opam_version = '1.2.2';
  my $opam_base = "opam-full-$opam_version";
  my $opam_build = path $root, 'build', $opam_base;
  my $opam_tgz = "$opam_base.tar.gz";
  my $opam_tar = path $cache, $opam_tgz;
  my $opam_url = "https://github.com/ocaml/opam/releases/download/$opam_version/$opam_tgz";

  <<BUILD;
cd $root/git &&
mkdir -p $build $versions $cache $opam_build &&
printf 'Extracting...' &&
git archive $version | (cd $build ; tar x) &&
printf 'Done\\n' &&
cd $build &&
./configure -prefix $versions/$version &&
sed -i -e 's%\\(chmod \\)-%\\1a-%' Makefile &&
make world.opt &&
make install &&
(test -f $opam_tar || curl -L -o $opam_tar $opam_url) &&
cd $opam_build &&
tar --strip-components=1 -zx < $opam_tar &&
sed -i -e 's!\\(sed -n -e .\\)s!\\11s!' configure &&
eval \$(VERMAN_EVAL=1 verman ocaml use $version) &&
./configure --prefix=$prefix &&
env -u MAKEFLAGS make lib-ext &&
make &&
make install
BUILD
}

1;
