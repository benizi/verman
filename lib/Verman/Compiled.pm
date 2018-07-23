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

sub _archive_path {
  my ($self, $tag) = @_;
  $self->upstream . "/archive/$tag.tar.gz"
}

sub _unpack_remote {
  my ($self, $tag) = @_;
  my $archive = $self->_archive_path($tag);
  "curl -Ls $archive | tar zx --strip-components=1"
}

sub _setup_build {
  my ($self, $version, $tag) = @_;
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $build = path $root, 'build', $version;
  my $prefix = path $versions, $version;
  my $unpack_remote = $self->_unpack_remote($tag);
  <<CHECKOUT;
set -e
mkdir -p $build $versions
cd $build
if test -d $root/git
then git --git-dir=$root/git archive $tag | tar x
else $unpack_remote
fi
CHECKOUT
}

sub _post_build {}

sub install {
  my $self = shift;
  my ($version, $tag) = @_;
  unless (defined $tag) {
    $tag = $self->_version_tag($version);
    push @_, $tag;
  }
  return 'No _make_install for '.ref($self) unless $self->can('_make_install');
  my $prefix = path $self->var($self->_versvar), $version;
  $self->_setup_build(@_),
  $self->_make_install($prefix, @_),
  $self->_post_build(@_)
}

sub _version_tag { $_[1] }

sub _tags {
  my $self = shift;
  my $root = $self->var($self->_rootvar);
  my $git = path $root, 'git';
  if (-d $git) {
    run qw/git --git-dir/, $git, 'tag'
  } else {
    map +(split '/')[-1],
    grep m{^\w+\s+refs/tags/[^\^/]+$},
    run qw/git ls-remote --tags/, $self->upstream
  }
}

1;
