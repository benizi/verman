package Verman::Ruby;
use strict;
use warnings;
use base 'Verman::Nix', 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util;

sub new {
  my $self = shift->SUPER::new(@_);
  my $root = $self->var($self->_rootvar);
  $self->var($self->_varname('build'), path $root, 'ruby-build');
  my $rbuild_repo = 'https://github.com/sstephenson/ruby-build';
  $self->var($self->_varname('build_repo'), $rbuild_repo);
  $self
}

sub _rbuild { my $self = shift; $self->var($self->_varname('build')) }
sub _rbuild_bin { path shift->_rbuild, 'bin', 'ruby-build' }

sub _non_nix_available {
  version_sort run shift->_rbuild_bin, '--definitions'
}

sub _install_rbuild {
  my $self = shift;
  my $rbuild = $self->_rbuild;
  return if -d $rbuild;
  my $base = basename $rbuild;
  my $rbuild_repo = $self->var($self->_varname('build_repo'));;
  mkpath $base || die "Couldn't mkdir -p $base: $!";
  system { 'git' } qw/git clone/, $rbuild_repo => $rbuild;
}

sub update {
  my $self = shift;
  my $rbuild = $self->_rbuild;
  if (!-d $rbuild) {
    $self->_install_rbuild;
  } else {
    push_dir $rbuild;
    system { 'git' } qw/git pull/;
    pop_dir;
  }
  -d $rbuild ? 'success' : 'fail'
}

sub after_path {
  my $self = shift;
  my $versions = $self->var($self->_versvar);
  my $version = $self->var($self->_vervar);
  my $base = path $versions, $version;
  my $gems = path $base, 'lib', 'ruby', 'gems';
  my $gem_bin = path $gems, 'bin';
  $self->pre_path($gem_bin);
  $self->env_vars(GEM_HOME => $gems, GEM_PATH => $gems);
  # TODO: jRuby-specific vars
}

sub _setup_build {}

sub _make_install {
  my ($self, $prefix, $version) = @_;
  my $rbuild = $self->_rbuild;
  $self->_install_rbuild;
  <<BUILD;
set -e
$rbuild/bin/ruby-build $version $prefix
BUILD
}

sub _post_build {
  my ($self, $version) = @_;
  <<BUILD;
verman ruby use $version gem install bundler
BUILD
}

1;
