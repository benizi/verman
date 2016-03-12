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
  $self->_get_source;
  my $root = $self->var($self->_rootvar);
  run qw/git --git-dir/, path($root, 'git'), 'fetch'
}

sub _get_source {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $git = path $root, 'git';
  return if -d $git;
  my $url = $self->var($self->_varname('upstream'));
  mkpath $root || die "Couldn't mkdir -p $root: $!";
  system { 'git' } qw/git clone --bare/, $url, $git
}

sub _setup_build {
  my ($self, $version) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;
  my $github = $self->upstream . "/archive/$version.tar.gz";
  <<CHECKOUT;
set -e
mkdir -p $build $versions
cd $build
if test -d $root/git
then git --git-dir=$root/git archive $version | tar x
else curl -Ls $github | tar zx --strip-components=1
fi
CHECKOUT
}

sub install {
  my ($self, $version) = @_;
  return 'No _make_install for '.ref($self) unless $self->can('_make_install');
  my $prefix = path $self->var($self->_versvar), $version;
  join '', $self->_setup_build($version), $self->_make_install($prefix, $version)
}

sub _tags {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $git = path $root, 'git';
  if (-d $git) {
    push_dir $git;
    my @tags = run qw/git tag/;
    pop_dir;
    @tags
  } else {
    map +(split '/')[-1],
    grep m{^\w+\s+refs/tags/[^\^/]+$},
    run qw/git ls-remote --tags/, $self->upstream
  }
}

1;
