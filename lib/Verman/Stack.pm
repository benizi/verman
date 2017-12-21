package Verman::Stack;
use strict;
use warnings;
use base 'Verman::SelfContained', 'Verman::Compiled';
use Verman::Util qw/path version_sort/;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->var($self->_varname('upstream'), 'https://github.com/commercialhaskell/stack');
  $self
}

sub _global_root {
  my ($self) = @_;
  path $self->var($self->_rootvar), 'root'
}

sub install {
  my ($self, $version) = @_;
  (my $vnum = $version) =~ s/^v//;
  my $download = $self->upstream . '/releases/download';
  my $file = "stack-$vnum-linux-x86_64.tar.gz";
  my $url = "$download/v$vnum/$file";
  my $root = $self->var($self->_rootvar);
  my $versions = $self->var($self->_versvar);
  my $prefix = path $versions, $version;
  my $stack_global_root = $self->_global_root;
  my $cache = path $root, 'downloads';
  <<BUILD;
mkdir -p $cache $prefix $stack_global_root &&
printf 'Downloading %s...\\n' "$url" &&
(test -f $cache/$file || curl -L -o $cache/$file $url) &&
printf 'Done\\n' &&
tar --strip-components=1 -xzf $cache/$file -C $prefix &&
mkdir -p $prefix/bin &&
mv $prefix/stack $prefix/bin/ &&
printf 'system-ghc: false\n' > $stack_global_root/config.yaml
BUILD
}

sub available {
  version_sort grep /^v/, shift->SUPER::_tags
}

sub after_path {
  my $self = shift;
  $self->env_vars(STACK_ROOT => $self->_global_root);
}

1;
